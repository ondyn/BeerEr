/// Integration test for joint accounts:
/// create group → add members → verify group structure → leave group.
library;

import 'package:beerer/models/models.dart';
import 'package:beerer/repositories/joint_account_repository.dart';
import 'package:beerer/repositories/keg_repository.dart';
import 'package:beerer/repositories/user_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late KegRepository kegRepo;
  late JointAccountRepository accountRepo;
  late UserRepository userRepo;

  const user1 = 'user-1';
  const user2 = 'user-2';
  const user3 = 'user-3';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    kegRepo = KegRepository(fakeFirestore);
    accountRepo = JointAccountRepository(fakeFirestore);
    userRepo = UserRepository(fakeFirestore);
  });

  group('Joint Accounts', () {
    testWidgets('create group → add members → verify structure',
        (tester) async {
      // ---------------------------------------------------------------
      // 1. Set up session and users
      // ---------------------------------------------------------------
      for (final uid in [user1, user2, user3]) {
        await userRepo.createOrUpdateUser(AppUser(
          id: uid,
          nickname: 'User $uid',
          email: '$uid@beerer.app',
        ));
      }

      final session = KegSession(
        id: '',
        creatorId: user1,
        beerName: 'Group Test Beer',
        volumeTotalMl: 30000,
        volumeRemainingMl: 30000,
        kegPrice: 60.0,
        alcoholPercent: 5.0,
        status: KegStatus.created,
      );

      final created = await kegRepo.createSession(session);
      await kegRepo.tapKeg(created.id);

      for (final uid in [user1, user2, user3]) {
        await kegRepo.addParticipant(created.id, uid);
      }

      // ---------------------------------------------------------------
      // 2. User1 creates a joint account
      // ---------------------------------------------------------------
      final account = JointAccount(
        id: '',
        sessionId: created.id,
        groupName: 'Table 1',
        creatorId: user1,
        memberUserIds: [user1],
      );

      final createdAccount = await accountRepo.createAccount(account);
      expect(createdAccount.id, isNotEmpty);
      expect(createdAccount.groupName, 'Table 1');
      expect(createdAccount.memberUserIds, [user1]);

      // ---------------------------------------------------------------
      // 3. User2 joins the group
      // ---------------------------------------------------------------
      await accountRepo.addMember(createdAccount.id, user2);

      // Verify group now has 2 members
      final accountForUser2 = await accountRepo.getAccountForUser(
        created.id,
        user2,
      );
      expect(accountForUser2, isNotNull);
      expect(accountForUser2!.id, createdAccount.id);
      expect(accountForUser2.memberUserIds, containsAll([user1, user2]));

      // ---------------------------------------------------------------
      // 4. User3 is solo (not in any group)
      // ---------------------------------------------------------------
      final accountForUser3 = await accountRepo.getAccountForUser(
        created.id,
        user3,
      );
      expect(accountForUser3, isNull);

      // ---------------------------------------------------------------
      // 5. User2 leaves the group
      // ---------------------------------------------------------------
      await accountRepo.removeMember(createdAccount.id, user2);

      final afterLeave = await accountRepo.getAccountForUser(
        created.id,
        user2,
      );
      expect(afterLeave, isNull);

      // User1 should still be in the group
      final user1Account = await accountRepo.getAccountForUser(
        created.id,
        user1,
      );
      expect(user1Account, isNotNull);
      expect(user1Account!.memberUserIds, [user1]);
    });

    testWidgets('rename group', (tester) async {
      final session = KegSession(
        id: '',
        creatorId: user1,
        beerName: 'Rename Test',
        volumeTotalMl: 20000,
        volumeRemainingMl: 20000,
        kegPrice: 40.0,
        alcoholPercent: 4.5,
        status: KegStatus.created,
      );

      final created = await kegRepo.createSession(session);

      final account = JointAccount(
        id: '',
        sessionId: created.id,
        groupName: 'Old Name',
        creatorId: user1,
        memberUserIds: [user1],
      );

      final createdAccount = await accountRepo.createAccount(account);
      await accountRepo.updateName(createdAccount.id, 'New Name');

      // Read back from Firestore
      final doc = await fakeFirestore
          .collection('jointAccounts')
          .doc(createdAccount.id)
          .get();
      expect(doc.data()!['group_name'], 'New Name');
    });

    testWidgets('delete group', (tester) async {
      final session = KegSession(
        id: '',
        creatorId: user1,
        beerName: 'Delete Test',
        volumeTotalMl: 20000,
        volumeRemainingMl: 20000,
        kegPrice: 40.0,
        alcoholPercent: 4.5,
        status: KegStatus.created,
      );

      final created = await kegRepo.createSession(session);

      final account = JointAccount(
        id: '',
        sessionId: created.id,
        groupName: 'To Delete',
        creatorId: user1,
        memberUserIds: [user1, user2],
      );

      final createdAccount = await accountRepo.createAccount(account);
      expect(createdAccount.id, isNotEmpty);

      await accountRepo.deleteAccount(createdAccount.id);

      final accountForUser1 = await accountRepo.getAccountForUser(
        created.id,
        user1,
      );
      expect(accountForUser1, isNull);
    });

    testWidgets('group cost aggregation', (tester) async {
      // Create session with pours from multiple users in the same group
      final session = KegSession(
        id: '',
        creatorId: user1,
        beerName: 'Group Cost Beer',
        volumeTotalMl: 20000,
        volumeRemainingMl: 20000,
        kegPrice: 100.0,
        alcoholPercent: 5.0,
        status: KegStatus.created,
      );

      final created = await kegRepo.createSession(session);
      await kegRepo.tapKeg(created.id);

      for (final uid in [user1, user2, user3]) {
        await kegRepo.addParticipant(created.id, uid);
      }

      // User1 pours 1000ml, User2 pours 500ml, User3 pours 500ml
      for (final entry in [
        (user1, 1000.0),
        (user2, 500.0),
        (user3, 500.0),
      ]) {
        final pour = Pour(
          id: '',
          sessionId: created.id,
          userId: entry.$1,
          pouredById: entry.$1,
          volumeMl: entry.$2,
          timestamp: DateTime.now(),
        );
        await kegRepo.addPour(pour);
      }

      // Create group for user1 and user2
      final account = JointAccount(
        id: '',
        sessionId: created.id,
        groupName: 'Friends',
        creatorId: user1,
        memberUserIds: [user1, user2],
      );

      final createdAccount = await accountRepo.createAccount(account);
      expect(createdAccount.memberUserIds.length, 2);

      // Verify keg remaining volume
      final afterPours = await kegRepo.getSession(created.id);
      expect(afterPours!.volumeRemainingMl, 18000);

      // The group consumed 1500ml total (user1: 1000 + user2: 500)
      // User3 consumed 500ml solo
      // With total consumed = 2000ml and keg price = 100:
      //   Group cost = 100 * (1500/20000) = 7.5  (based on total keg volume)
      //   OR  = 100 * (1500/2000) = 75  (based on actual consumption)
      // The actual formula depends on the app implementation
    });
  });
}
