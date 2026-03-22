/// Integration test for joining a keg session.
///
/// Simulates the flow where a user joins an existing session,
/// gets added as a participant, and can then pour beer.
library;

import 'package:beerer/models/models.dart';
import 'package:beerer/repositories/keg_repository.dart';
import 'package:beerer/repositories/user_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late KegRepository kegRepo;
  late UserRepository userRepo;

  const creatorId = 'creator-user';
  const joinerId = 'joiner-user';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    kegRepo = KegRepository(fakeFirestore);
    userRepo = UserRepository(fakeFirestore);
  });

  group('Join Session', () {
    testWidgets('user joins session and becomes a participant',
        (tester) async {
      // ---------------------------------------------------------------
      // 1. Creator sets up session
      // ---------------------------------------------------------------
      await userRepo.createOrUpdateUser(const AppUser(
        id: creatorId,
        nickname: 'Creator',
        email: 'creator@beerer.app',
      ));

      final session = KegSession(
        id: '',
        creatorId: creatorId,
        beerName: 'Party Pilsner',
        volumeTotalMl: 50000,
        volumeRemainingMl: 50000,
        kegPrice: 80.0,
        alcoholPercent: 4.8,
        predefinedVolumesMl: [500, 300],
        status: KegStatus.created,
      );

      final created = await kegRepo.createSession(session);
      await kegRepo.addParticipant(created.id, creatorId);
      await kegRepo.tapKeg(created.id);

      // Verify session has a join link
      final fetchedSession = await kegRepo.getSession(created.id);
      expect(fetchedSession!.joinLink, isNotNull);
      expect(fetchedSession.joinLink, contains(created.id));

      // ---------------------------------------------------------------
      // 2. Joiner creates their profile
      // ---------------------------------------------------------------
      await userRepo.createOrUpdateUser(const AppUser(
        id: joinerId,
        nickname: 'Joiner',
        email: 'joiner@beerer.app',
        weightKg: 70.0,
        age: 25,
        gender: 'male',
        preferences: {
          'show_stats': true,
          'show_bac': false,
        },
      ));

      // ---------------------------------------------------------------
      // 3. Joiner joins the session (simulates the join screen flow)
      // ---------------------------------------------------------------
      await kegRepo.addParticipant(created.id, joinerId);

      // Verify joiner is in the participant list
      final participantsSnap = await fakeFirestore
          .collection('kegSessions')
          .doc(created.id)
          .get();
      final participantIds =
          (participantsSnap.data()!['participant_ids'] as List<dynamic>)
              .cast<String>();
      expect(participantIds, contains(creatorId));
      expect(participantIds, contains(joinerId));
      expect(participantIds.length, 2);

      // ---------------------------------------------------------------
      // 4. Joiner pours beer
      // ---------------------------------------------------------------
      final pour = Pour(
        id: '',
        sessionId: created.id,
        userId: joinerId,
        pouredById: joinerId,
        volumeMl: 500,
        timestamp: DateTime.now(),
      );

      final createdPour = await kegRepo.addPour(pour);
      expect(createdPour.id, isNotEmpty);
      expect(createdPour.userId, joinerId);

      final afterPour = await kegRepo.getSession(created.id);
      expect(afterPour!.volumeRemainingMl, 49500);

      // ---------------------------------------------------------------
      // 5. Creator pours for joiner
      // ---------------------------------------------------------------
      final pourForJoiner = Pour(
        id: '',
        sessionId: created.id,
        userId: joinerId,
        pouredById: creatorId,
        volumeMl: 300,
        timestamp: DateTime.now(),
      );

      final createdPourFor = await kegRepo.addPour(pourForJoiner);
      expect(createdPourFor.userId, joinerId);
      expect(createdPourFor.pouredById, creatorId);

      final afterPourFor = await kegRepo.getSession(created.id);
      expect(afterPourFor!.volumeRemainingMl, 49200);
    });

    testWidgets('joiner profile is readable after creation',
        (tester) async {
      await userRepo.createOrUpdateUser(const AppUser(
        id: joinerId,
        nickname: 'Test Joiner',
        email: 'joiner@beerer.app',
        weightKg: 75.0,
        age: 28,
        gender: 'female',
      ));

      final user = await userRepo.getUser(joinerId);
      expect(user, isNotNull);
      expect(user!.nickname, 'Test Joiner');
      expect(user.gender, 'female');
      expect(user.weightKg, 75.0);
    });

    testWidgets('manual user creation and merge with real user',
        (tester) async {
      // Create session
      final session = KegSession(
        id: '',
        creatorId: creatorId,
        beerName: 'Merge Test',
        volumeTotalMl: 20000,
        volumeRemainingMl: 20000,
        kegPrice: 40.0,
        alcoholPercent: 5.0,
        status: KegStatus.created,
      );

      final created = await kegRepo.createSession(session);
      await kegRepo.tapKeg(created.id);

      // Creator adds a manual user
      final manualUser =
          await kegRepo.addManualUser(created.id, 'Guest Alice');
      expect(manualUser.id, isNotEmpty);
      expect(manualUser.nickname, 'Guest Alice');

      // Pour for the manual user
      final guestPour = Pour(
        id: '',
        sessionId: created.id,
        userId: manualUser.id,
        pouredById: creatorId,
        volumeMl: 500,
        timestamp: DateTime.now(),
      );

      // Use addPourForReview since manual user pours may bypass normal flow
      // Actually, addPour should work since keg is active
      final createdGuestPour = await kegRepo.addPour(guestPour);
      expect(createdGuestPour.userId, manualUser.id);

      // Now real Alice joins and merges
      const realAliceId = 'real-alice';
      await kegRepo.addParticipant(created.id, realAliceId);
      await kegRepo.mergeManualUser(
        sessionId: created.id,
        manualUserId: manualUser.id,
        realUserId: realAliceId,
      );

      // Verify the pour now belongs to Alice
      final pourDoc = await fakeFirestore
          .collection('pours')
          .doc(createdGuestPour.id)
          .get();
      expect(pourDoc.data()!['user_id'], realAliceId);
      expect(pourDoc.data()!['poured_by_id'], realAliceId);
    });
  });
}
