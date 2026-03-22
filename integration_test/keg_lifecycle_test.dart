/// Integration test for the full keg lifecycle:
/// create keg → tap keg → pour beer → undo pour.
///
/// Uses [FakeFirebaseFirestore] so no real Firebase backend is required.
library;

import 'package:beerer/models/models.dart';
import 'package:beerer/repositories/keg_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late KegRepository kegRepo;

  const testUserId = 'test-user-1';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    kegRepo = KegRepository(fakeFirestore);
  });

  group('Keg Lifecycle', () {
    testWidgets('create → tap → pour → undo pour', (tester) async {
      // ---------------------------------------------------------------
      // 1. Create a keg session (status: created)
      // ---------------------------------------------------------------
      final newSession = KegSession(
        id: '',
        creatorId: testUserId,
        beerName: 'Test Lager',
        volumeTotalMl: 30000, // 30 L
        volumeRemainingMl: 30000,
        kegPrice: 50.0,
        alcoholPercent: 5.0,
        predefinedVolumesMl: [500, 300],
        status: KegStatus.created,
      );

      final created = await kegRepo.createSession(newSession);
      expect(created.id, isNotEmpty);
      expect(created.joinLink, contains(created.id));

      // Verify the session was persisted with status "created"
      final fetched = await kegRepo.getSession(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.status, KegStatus.created);
      expect(fetched.beerName, 'Test Lager');
      expect(fetched.volumeRemainingMl, 30000);
      expect(fetched.startTime, isNull);

      // Add creator as participant
      await kegRepo.addParticipant(created.id, testUserId);

      // ---------------------------------------------------------------
      // 2. Tap the keg (status: created → active)
      // ---------------------------------------------------------------
      await kegRepo.tapKeg(created.id);

      final tapped = await kegRepo.getSession(created.id);
      expect(tapped, isNotNull);
      expect(tapped!.status, KegStatus.active);
      // Note: FakeFirebaseFirestore does not support FieldValue.serverTimestamp()
      // in the same way as real Firestore, so start_time may remain null.
      // This is a known limitation of the fake package.

      // ---------------------------------------------------------------
      // 3. Pour beer (500 ml)
      // ---------------------------------------------------------------
      final pour = Pour(
        id: '',
        sessionId: created.id,
        userId: testUserId,
        pouredById: testUserId,
        volumeMl: 500,
        timestamp: DateTime.now(),
      );

      final createdPour = await kegRepo.addPour(pour);
      expect(createdPour.id, isNotEmpty);
      expect(createdPour.volumeMl, 500);

      // Verify keg volume decreased
      final afterPour = await kegRepo.getSession(created.id);
      expect(afterPour!.volumeRemainingMl, 29500);

      // ---------------------------------------------------------------
      // 4. Pour again (300 ml)
      // ---------------------------------------------------------------
      final pour2 = Pour(
        id: '',
        sessionId: created.id,
        userId: testUserId,
        pouredById: testUserId,
        volumeMl: 300,
        timestamp: DateTime.now(),
      );

      final createdPour2 = await kegRepo.addPour(pour2);
      expect(createdPour2.id, isNotEmpty);

      final afterPour2 = await kegRepo.getSession(created.id);
      expect(afterPour2!.volumeRemainingMl, 29200);

      // ---------------------------------------------------------------
      // 5. Undo the second pour
      // ---------------------------------------------------------------
      await kegRepo.undoPour(createdPour2);

      final afterUndo = await kegRepo.getSession(created.id);
      expect(afterUndo!.volumeRemainingMl, 29500);

      // Verify the pour is soft-deleted
      final undoneDoc = await fakeFirestore
          .collection('pours')
          .doc(createdPour2.id)
          .get();
      expect(undoneDoc.data()!['undone'], true);

      // First pour should still be active
      final firstPourDoc = await fakeFirestore
          .collection('pours')
          .doc(createdPour.id)
          .get();
      expect(firstPourDoc.data()!['undone'], false);
    });

    testWidgets('cannot pour on paused keg', (tester) async {
      // Create and tap
      final session = KegSession(
        id: '',
        creatorId: testUserId,
        beerName: 'Paused Beer',
        volumeTotalMl: 10000,
        volumeRemainingMl: 10000,
        kegPrice: 30.0,
        alcoholPercent: 4.5,
        status: KegStatus.created,
      );

      final created = await kegRepo.createSession(session);
      await kegRepo.tapKeg(created.id);

      // Pause the keg
      await kegRepo.updateStatus(created.id, KegStatus.paused);

      // Try to pour — should fail
      final pour = Pour(
        id: '',
        sessionId: created.id,
        userId: testUserId,
        pouredById: testUserId,
        volumeMl: 500,
        timestamp: DateTime.now(),
      );

      expect(
        () => kegRepo.addPour(pour),
        throwsA(isA<StateError>()),
      );
    });

    testWidgets('cannot pour on done keg', (tester) async {
      final session = KegSession(
        id: '',
        creatorId: testUserId,
        beerName: 'Done Beer',
        volumeTotalMl: 10000,
        volumeRemainingMl: 10000,
        kegPrice: 30.0,
        alcoholPercent: 4.5,
        status: KegStatus.created,
      );

      final created = await kegRepo.createSession(session);
      await kegRepo.tapKeg(created.id);
      await kegRepo.updateStatus(created.id, KegStatus.done);

      final pour = Pour(
        id: '',
        sessionId: created.id,
        userId: testUserId,
        pouredById: testUserId,
        volumeMl: 500,
        timestamp: DateTime.now(),
      );

      expect(
        () => kegRepo.addPour(pour),
        throwsA(isA<StateError>()),
      );
    });

    testWidgets('cannot pour more than remaining volume', (tester) async {
      final session = KegSession(
        id: '',
        creatorId: testUserId,
        beerName: 'Small Keg',
        volumeTotalMl: 1000,
        volumeRemainingMl: 1000,
        kegPrice: 10.0,
        alcoholPercent: 5.0,
        status: KegStatus.created,
      );

      final created = await kegRepo.createSession(session);
      await kegRepo.tapKeg(created.id);

      final pour = Pour(
        id: '',
        sessionId: created.id,
        userId: testUserId,
        pouredById: testUserId,
        volumeMl: 1500, // More than remaining
        timestamp: DateTime.now(),
      );

      expect(
        () => kegRepo.addPour(pour),
        throwsA(isA<StateError>()),
      );
    });

    testWidgets('keg status transitions: created → active → paused → active → done',
        (tester) async {
      final session = KegSession(
        id: '',
        creatorId: testUserId,
        beerName: 'Lifecycle Beer',
        volumeTotalMl: 20000,
        volumeRemainingMl: 20000,
        kegPrice: 40.0,
        alcoholPercent: 5.0,
        status: KegStatus.created,
      );

      final created = await kegRepo.createSession(session);
      expect((await kegRepo.getSession(created.id))!.status,
          KegStatus.created);

      // Tap keg
      await kegRepo.tapKeg(created.id);
      expect((await kegRepo.getSession(created.id))!.status,
          KegStatus.active);

      // Pause
      await kegRepo.updateStatus(created.id, KegStatus.paused);
      expect((await kegRepo.getSession(created.id))!.status,
          KegStatus.paused);

      // Resume
      await kegRepo.tapKeg(created.id);
      expect((await kegRepo.getSession(created.id))!.status,
          KegStatus.active);

      // Done
      await kegRepo.updateStatus(created.id, KegStatus.done);
      expect((await kegRepo.getSession(created.id))!.status,
          KegStatus.done);
    });
  });
}
