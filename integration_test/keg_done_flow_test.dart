/// Integration test for the keg-done flow with final cost calculation.
///
/// Covers: multiple participants pour → keg marked done →
/// per-user cost calculated based on actual consumption.
library;

import 'package:beerer/models/models.dart';
import 'package:beerer/repositories/joint_account_repository.dart';
import 'package:beerer/repositories/keg_repository.dart';
import 'package:beerer/repositories/user_repository.dart';
import 'package:beerer/utils/stats_calculator.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late KegRepository kegRepo;
  late JointAccountRepository accountRepo;
  late UserRepository userRepo;

  const alice = 'alice';
  const bob = 'bob';
  const carol = 'carol';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    kegRepo = KegRepository(fakeFirestore);
    accountRepo = JointAccountRepository(fakeFirestore);
    userRepo = UserRepository(fakeFirestore);
  });

  group('Keg Done — Final Calculation', () {
    testWidgets('per-user costs based on actual consumption', (tester) async {
      // ---------------------------------------------------------------
      // 1. Setup: create users and session
      // ---------------------------------------------------------------
      for (final uid in [alice, bob, carol]) {
        await userRepo.createOrUpdateUser(AppUser(
          id: uid,
          nickname: uid,
          email: '$uid@beerer.app',
        ));
      }

      const session = KegSession(
        id: '',
        creatorId: alice,
        beerName: 'Final Bill IPA',
        volumeTotalMl: 30000, // 30L
        volumeRemainingMl: 30000,
        kegPrice: 120.0,
        alcoholPercent: 6.0,
        predefinedVolumesMl: [500, 300],
        status: KegStatus.created,
      );

      final created = await kegRepo.createSession(session);
      await kegRepo.tapKeg(created.id);

      for (final uid in [alice, bob, carol]) {
        await kegRepo.addParticipant(created.id, uid);
      }

      // ---------------------------------------------------------------
      // 2. Pour phase
      //    Alice: 3 × 500ml = 1500ml
      //    Bob:   2 × 500ml = 1000ml
      //    Carol: 1 × 500ml = 500ml
      //    Total consumed: 3000ml
      // ---------------------------------------------------------------
      final pours = <Pour>[];

      for (var i = 0; i < 3; i++) {
        final p = await kegRepo.addPour(Pour(
          id: '',
          sessionId: created.id,
          userId: alice,
          pouredById: alice,
          volumeMl: 500,
          timestamp: DateTime.now().add(Duration(minutes: i * 10)),
        ));
        pours.add(p);
      }

      for (var i = 0; i < 2; i++) {
        final p = await kegRepo.addPour(Pour(
          id: '',
          sessionId: created.id,
          userId: bob,
          pouredById: bob,
          volumeMl: 500,
          timestamp: DateTime.now().add(Duration(minutes: i * 10 + 5)),
        ));
        pours.add(p);
      }

      final carolPour = await kegRepo.addPour(Pour(
        id: '',
        sessionId: created.id,
        userId: carol,
        pouredById: carol,
        volumeMl: 500,
        timestamp: DateTime.now().add(const Duration(minutes: 15)),
      ));
      pours.add(carolPour);

      // Verify volume remaining
      final beforeDone = await kegRepo.getSession(created.id);
      expect(beforeDone!.volumeRemainingMl, 27000); // 30000 - 3000

      // ---------------------------------------------------------------
      // 3. Mark keg as done
      // ---------------------------------------------------------------
      await kegRepo.updateStatus(created.id, KegStatus.done);

      final done = await kegRepo.getSession(created.id);
      expect(done!.status, KegStatus.done);

      // ---------------------------------------------------------------
      // 4. Calculate final costs using StatsCalculator
      //    Based on ACTUAL consumption (3000ml), not total keg (30000ml)
      //    Alice: 1500/3000 * 120 = 60.0
      //    Bob:   1000/3000 * 120 = 40.0
      //    Carol:  500/3000 * 120 = 20.0
      // ---------------------------------------------------------------
      final totalPoured = StatsCalculator.totalPouredMl(pours);
      expect(totalPoured, 3000.0);

      final aliceCost = StatsCalculator.userCostByConsumption(
        pours, alice, 120.0,
      );
      expect(aliceCost, closeTo(60.0, 0.01));

      final bobCost = StatsCalculator.userCostByConsumption(
        pours, bob, 120.0,
      );
      expect(bobCost, closeTo(40.0, 0.01));

      final carolCost = StatsCalculator.userCostByConsumption(
        pours, carol, 120.0,
      );
      expect(carolCost, closeTo(20.0, 0.01));

      // Sum of all costs equals keg price
      expect(aliceCost + bobCost + carolCost, closeTo(120.0, 0.01));

      // ---------------------------------------------------------------
      // 5. Verify consumption ratios
      // ---------------------------------------------------------------
      expect(
        StatsCalculator.userConsumptionRatio(pours, alice),
        closeTo(0.5, 0.01),
      );
      expect(
        StatsCalculator.userConsumptionRatio(pours, bob),
        closeTo(1 / 3, 0.01),
      );
      expect(
        StatsCalculator.userConsumptionRatio(pours, carol),
        closeTo(1 / 6, 0.01),
      );

      // ---------------------------------------------------------------
      // 6. Verify beer counts
      // ---------------------------------------------------------------
      expect(StatsCalculator.beerCount(pours, alice), closeTo(3.0, 0.01));
      expect(StatsCalculator.beerCount(pours, bob), closeTo(2.0, 0.01));
      expect(StatsCalculator.beerCount(pours, carol), closeTo(1.0, 0.01));

      // ---------------------------------------------------------------
      // 7. Verify pure alcohol calculation
      // ---------------------------------------------------------------
      // Total: 3000ml at 6% = 180ml pure alcohol
      expect(
        StatsCalculator.pureAlcoholMl(pours, 6.0),
        closeTo(180.0, 0.01),
      );

      // Alice: 1500ml at 6% = 90ml pure alcohol
      expect(
        StatsCalculator.userPureAlcoholMl(pours, alice, 6.0),
        closeTo(90.0, 0.01),
      );
    });

    testWidgets('done flow with joint accounts — group cost', (tester) async {
      // Create session and users
      for (final uid in [alice, bob, carol]) {
        await userRepo.createOrUpdateUser(AppUser(
          id: uid,
          nickname: uid,
          email: '$uid@beerer.app',
        ));
      }

      const session = KegSession(
        id: '',
        creatorId: alice,
        beerName: 'Group Bill Ale',
        volumeTotalMl: 20000,
        volumeRemainingMl: 20000,
        kegPrice: 100.0,
        alcoholPercent: 5.0,
        status: KegStatus.created,
      );

      final created = await kegRepo.createSession(session);
      await kegRepo.tapKeg(created.id);

      for (final uid in [alice, bob, carol]) {
        await kegRepo.addParticipant(created.id, uid);
      }

      // Alice and Bob in a group, Carol is solo
      await accountRepo.createAccount(JointAccount(
        id: '',
        sessionId: created.id,
        groupName: 'Roommates',
        creatorId: alice,
        memberUserIds: [alice, bob],
      ));

      // Pour:
      //   Alice: 1000ml, Bob: 1000ml, Carol: 500ml
      //   Total: 2500ml
      final pours = <Pour>[];
      for (final entry in [
        (alice, 1000.0),
        (bob, 1000.0),
        (carol, 500.0),
      ]) {
        final p = await kegRepo.addPour(Pour(
          id: '',
          sessionId: created.id,
          userId: entry.$1,
          pouredById: entry.$1,
          volumeMl: entry.$2,
          timestamp: DateTime.now(),
        ));
        pours.add(p);
      }

      // Mark done
      await kegRepo.updateStatus(created.id, KegStatus.done);

      // Group cost (Alice + Bob): 2000/2500 * 100 = 80.0
      final groupCost = StatsCalculator.groupCostByConsumption(
        pours,
        [alice, bob],
        100.0,
      );
      expect(groupCost, closeTo(80.0, 0.01));

      // Carol solo: 500/2500 * 100 = 20.0
      final carolCost = StatsCalculator.userCostByConsumption(
        pours, carol, 100.0,
      );
      expect(carolCost, closeTo(20.0, 0.01));

      // Group consumption ratio
      final groupRatio = StatsCalculator.groupConsumptionRatio(
        pours,
        [alice, bob],
      );
      expect(groupRatio, closeTo(0.8, 0.01));

      // Verify the group structure
      final accountForAlice = await accountRepo.getAccountForUser(
        created.id,
        alice,
      );
      expect(accountForAlice, isNotNull);
      expect(accountForAlice!.groupName, 'Roommates');
      expect(accountForAlice.memberUserIds, containsAll([alice, bob]));

      final accountForCarol = await accountRepo.getAccountForUser(
        created.id,
        carol,
      );
      expect(accountForCarol, isNull);
    });

    testWidgets('bill review — add pour after keg is done', (tester) async {
      const session = KegSession(
        id: '',
        creatorId: alice,
        beerName: 'Review Test',
        volumeTotalMl: 10000,
        volumeRemainingMl: 10000,
        kegPrice: 50.0,
        alcoholPercent: 5.0,
        status: KegStatus.created,
      );

      final created = await kegRepo.createSession(session);
      await kegRepo.tapKeg(created.id);
      await kegRepo.addParticipant(created.id, alice);

      // Pour and mark done
      final pour = await kegRepo.addPour(Pour(
        id: '',
        sessionId: created.id,
        userId: alice,
        pouredById: alice,
        volumeMl: 500,
        timestamp: DateTime.now(),
      ));

      await kegRepo.updateStatus(created.id, KegStatus.done);

      // Creator adds a pour via bill review (doesn't affect keg volume)
      final reviewPour = await kegRepo.addPourForReview(Pour(
        id: '',
        sessionId: created.id,
        userId: bob,
        pouredById: alice,
        volumeMl: 500,
        timestamp: DateTime.now(),
      ));
      expect(reviewPour.id, isNotEmpty);

      // Keg volume should NOT change (bill review doesn't modify it)
      final afterReview = await kegRepo.getSession(created.id);
      expect(afterReview!.volumeRemainingMl, 9500);

      // Creator undo-s a pour during review
      await kegRepo.undoPourForReview(pour);

      final undoneDoc = await fakeFirestore
          .collection('pours')
          .doc(pour.id)
          .get();
      expect(undoneDoc.data()!['undone'], true);

      // Keg volume still unchanged
      final afterUndoReview = await kegRepo.getSession(created.id);
      expect(afterUndoReview!.volumeRemainingMl, 9500);
    });

    testWidgets('price per reference beer calculation', (tester) async {
      // 30L keg at 120€ → 0.5L costs 2.0€
      final pricePerHalfLitre = StatsCalculator.pricePerReferenceBeer(
        120.0,
        30000.0,
      );
      expect(pricePerHalfLitre, closeTo(2.0, 0.01));

      // Edge case: empty keg
      final zero = StatsCalculator.pricePerReferenceBeer(100.0, 0.0);
      expect(zero, isNull);
    });
  });
}
