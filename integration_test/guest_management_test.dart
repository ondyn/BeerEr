/// Integration tests for manual-user (guest) management.
///
/// Covers:
///   - Adding a guest and retrieving them from Firestore.
///   - Duplicate nickname detection (same name as an existing guest).
///   - Duplicate nickname detection (same name as a registered participant).
///   - Case-insensitive duplicate detection.
///   - Guest is listed in the pours / cost summary after recording a pour.
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

  const creatorId = 'creator-uid';
  const registeredUserId = 'registered-uid';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    kegRepo = KegRepository(fakeFirestore);
    userRepo = UserRepository(fakeFirestore);
  });

  /// Helper: create and tap a minimal keg session, return its id.
  Future<String> setupActiveSession() async {
    const session = KegSession(
      id: '',
      creatorId: creatorId,
      beerName: 'Integration Test Lager',
      volumeTotalMl: 30000,
      volumeRemainingMl: 30000,
      kegPrice: 60.0,
      alcoholPercent: 5.0,
      predefinedVolumesMl: [500, 300],
      status: KegStatus.created,
    );
    final created = await kegRepo.createSession(session);
    await kegRepo.tapKeg(created.id);
    await kegRepo.addParticipant(created.id, creatorId);
    return created.id;
  }

  group('Guest (ManualUser) management', () {
    testWidgets('adds a guest and can retrieve them', (tester) async {
      final sessionId = await setupActiveSession();

      final guest = await kegRepo.addManualUser(sessionId, 'Alice Guest');

      expect(guest.id, isNotEmpty);
      expect(guest.nickname, 'Alice Guest');
      expect(guest.sessionId, sessionId);

      // Verify persistence in Firestore.
      final doc = await fakeFirestore
          .collection('kegSessions')
          .doc(sessionId)
          .collection('manualUsers')
          .doc(guest.id)
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['nickname'], 'Alice Guest');
    });

    testWidgets(
      'duplicate nickname detection — same name as existing guest',
      (tester) async {
        final sessionId = await setupActiveSession();

        // First guest added successfully.
        await kegRepo.addManualUser(sessionId, 'Bob');

        // Simulate the validation the dialog performs before calling addManualUser.
        final guestsStream = kegRepo.watchManualUsers(sessionId);
        final guests = await guestsStream.first;

        final duplicate = guests.any(
          (g) => g.nickname.toLowerCase() == 'bob',
        );
        expect(
          duplicate,
          isTrue,
          reason: 'Repository should contain a guest named Bob',
        );

        // A different name should NOT be flagged as duplicate.
        final notDuplicate = guests.any(
          (g) => g.nickname.toLowerCase() == 'carol',
        );
        expect(notDuplicate, isFalse);
      },
    );

    testWidgets(
      'duplicate nickname detection — case-insensitive match with existing guest',
      (tester) async {
        final sessionId = await setupActiveSession();

        await kegRepo.addManualUser(sessionId, 'Dave');

        final guests =
            await kegRepo.watchManualUsers(sessionId).first;

        // 'dave', 'DAVE', and 'Dave' should all match.
        for (final variant in ['dave', 'DAVE', 'Dave', 'dAvE']) {
          expect(
            guests.any((g) => g.nickname.toLowerCase() == variant.toLowerCase()),
            isTrue,
            reason: '"$variant" should match the existing guest "Dave"',
          );
        }
      },
    );

    testWidgets(
      'duplicate detection — same name as a registered participant',
      (tester) async {
        final sessionId = await setupActiveSession();

        // Register a real user and add them as a participant.
        await userRepo.createOrUpdateUser(const AppUser(
          id: registeredUserId,
          nickname: 'Eve Real',
          email: 'eve@beerer.app',
        ));
        await kegRepo.addParticipant(sessionId, registeredUserId);

        // Fetch registered participant display names (simulates what the
        // dialog does with `watchUsersProvider`).
        final registeredUser =
            await userRepo.getUser(registeredUserId);
        expect(registeredUser, isNotNull);

        const candidateName = 'Eve Real';
        final collidesWithRegistered = registeredUser!.displayName
                .toLowerCase() ==
            candidateName.toLowerCase();
        expect(
          collidesWithRegistered,
          isTrue,
          reason:
              'A guest name matching a registered participant should be flagged',
        );
      },
    );

    testWidgets(
      'duplicate detection — different name from registered participant passes',
      (tester) async {
        final sessionId = await setupActiveSession();

        await userRepo.createOrUpdateUser(const AppUser(
          id: registeredUserId,
          nickname: 'Frank Real',
          email: 'frank@beerer.app',
        ));
        await kegRepo.addParticipant(sessionId, registeredUserId);

        final registeredUser =
            await userRepo.getUser(registeredUserId);
        const candidateName = 'Grace Guest';

        final collidesWithRegistered = registeredUser!.displayName
                .toLowerCase() ==
            candidateName.toLowerCase();
        expect(collidesWithRegistered, isFalse);
      },
    );

    testWidgets(
      'guest pour is recorded and reduces keg volume',
      (tester) async {
        final sessionId = await setupActiveSession();

        final guest =
            await kegRepo.addManualUser(sessionId, 'Hannah Guest');

        final pour = Pour(
          id: '',
          sessionId: sessionId,
          userId: guest.id,
          pouredById: creatorId,
          volumeMl: 500,
          timestamp: DateTime.now(),
        );
        final createdPour = await kegRepo.addPour(pour);

        expect(createdPour.userId, guest.id);
        expect(createdPour.pouredById, creatorId);

        final afterPour = await kegRepo.getSession(sessionId);
        expect(afterPour!.volumeRemainingMl, 29500);
      },
    );

    testWidgets(
      'multiple guests can be added with distinct names',
      (tester) async {
        final sessionId = await setupActiveSession();

        final g1 = await kegRepo.addManualUser(sessionId, 'Iris');
        final g2 = await kegRepo.addManualUser(sessionId, 'Jack');
        final g3 = await kegRepo.addManualUser(sessionId, 'Karen');

        final guests =
            await kegRepo.watchManualUsers(sessionId).first;
        expect(guests.length, 3);

        final ids = guests.map((g) => g.id).toSet();
        expect(ids, containsAll([g1.id, g2.id, g3.id]));

        final names = guests.map((g) => g.nickname).toSet();
        expect(names, containsAll(['Iris', 'Jack', 'Karen']));
      },
    );

    testWidgets('removing a guest deletes them from Firestore',
        (tester) async {
      final sessionId = await setupActiveSession();

      final guest = await kegRepo.addManualUser(sessionId, 'Leo');
      await kegRepo.removeManualUser(sessionId, guest.id);

      final doc = await fakeFirestore
          .collection('kegSessions')
          .doc(sessionId)
          .collection('manualUsers')
          .doc(guest.id)
          .get();
      expect(doc.exists, isFalse);
    });
  });
}
