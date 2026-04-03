/// Integration test for the account lifecycle:
/// register → login → soft-delete account → re-register with relink.
///
/// Uses [FakeFirebaseFirestore] so no real Firebase backend is required.
/// Validates the [UserRepository] methods that power the account
/// deletion and re-registration flows.
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
  late UserRepository userRepo;
  late KegRepository kegRepo;

  const userId = 'user-abc-123';
  const userEmail = 'alice@beerer.app';
  const userNickname = 'Alice';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    userRepo = UserRepository(fakeFirestore);
    kegRepo = KegRepository(fakeFirestore);
  });

  group('Account Lifecycle', () {
    // -----------------------------------------------------------------
    // 1. Register → verify profile creation
    // -----------------------------------------------------------------
    testWidgets('register creates user profile in Firestore', (tester) async {
      await userRepo.createOrUpdateUser(const AppUser(
        id: userId,
        nickname: userNickname,
        email: userEmail,
        weightKg: 75.0,
        age: 28,
        gender: 'male',
        authProvider: 'email',
      ));

      final user = await userRepo.getUser(userId);
      expect(user, isNotNull);
      expect(user!.nickname, userNickname);
      expect(user.email, userEmail);
      expect(user.weightKg, 75.0);
      expect(user.age, 28);
      expect(user.gender, 'male');
      expect(user.suspended, false);
      expect(user.deletedAt, isNull);
    });

    // -----------------------------------------------------------------
    // 2. Login → user profile still exists and can be read
    // -----------------------------------------------------------------
    testWidgets('login reads existing user profile', (tester) async {
      // Simulate previous registration.
      await userRepo.createOrUpdateUser(const AppUser(
        id: userId,
        nickname: userNickname,
        email: userEmail,
        weightKg: 75.0,
        age: 28,
        gender: 'male',
        authProvider: 'email',
      ));

      // Simulate login — the app watches the user doc.
      final user = await userRepo.getUser(userId);
      expect(user, isNotNull);
      expect(user!.nickname, userNickname);
      expect(user.displayName, userNickname);
      expect(user.suspended, false);
    });

    // -----------------------------------------------------------------
    // 3. Update profile → re-login → profile persists
    // -----------------------------------------------------------------
    testWidgets('updated profile survives re-login', (tester) async {
      await userRepo.createOrUpdateUser(const AppUser(
        id: userId,
        nickname: userNickname,
        email: userEmail,
        weightKg: 75.0,
        age: 28,
        gender: 'male',
        authProvider: 'email',
      ));

      // Update the profile (simulates editing in-app).
      await userRepo.createOrUpdateUser(const AppUser(
        id: userId,
        nickname: 'Alice B.',
        email: userEmail,
        weightKg: 68.0,
        age: 29,
        gender: 'female',
        authProvider: 'email',
      ));

      // Re-login — read the profile again.
      final user = await userRepo.getUser(userId);
      expect(user, isNotNull);
      expect(user!.nickname, 'Alice B.');
      expect(user.weightKg, 68.0);
      expect(user.age, 29);
      expect(user.gender, 'female');
    });

    // -----------------------------------------------------------------
    // 4. Soft-delete account
    // -----------------------------------------------------------------
    testWidgets('soft-delete clears personal data and marks suspended',
        (tester) async {
      // Setup — create user.
      await userRepo.createOrUpdateUser(const AppUser(
        id: userId,
        nickname: userNickname,
        email: userEmail,
        weightKg: 75.0,
        age: 28,
        gender: 'male',
        authProvider: 'email',
        preferences: {'show_stats': true, 'notify_pour_for_me': true},
      ));

      // Soft-delete (mirrors what settings_screen.dart now does).
      await userRepo.softDeleteUser(userId);

      // Verify the Firestore doc directly.
      final snap =
          await fakeFirestore.collection('users').doc(userId).get();
      expect(snap.exists, true);
      final data = snap.data()!;
      expect(data['nickname'], 'Deleted User');
      expect(data['weight_kg'], 0);
      expect(data['age'], 0);
      expect(data['suspended'], true);
      expect(data['deleted_at'], isNotNull);
      // Email must be preserved for future relink.
      expect(data['email'], userEmail);

      // Read through the repository — displayName helper should return
      // 'Deleted User'.
      final user = await userRepo.getUser(userId);
      expect(user, isNotNull);
      expect(user!.suspended, true);
      expect(user.displayName, 'Deleted User');
      expect(user.weightKg, 0);
    });

    // -----------------------------------------------------------------
    // 5. findSuspendedByEmail
    // -----------------------------------------------------------------
    testWidgets('findSuspendedByEmail locates the soft-deleted account',
        (tester) async {
      // Create and then soft-delete.
      await userRepo.createOrUpdateUser(const AppUser(
        id: userId,
        nickname: userNickname,
        email: userEmail,
        weightKg: 75.0,
        age: 28,
        gender: 'male',
        authProvider: 'email',
      ));
      await userRepo.softDeleteUser(userId);

      // Search by email.
      final found = await userRepo.findSuspendedByEmail(userEmail);
      expect(found, isNotNull);
      expect(found!.id, userId);
      expect(found.email, userEmail);
      expect(found.suspended, true);

      // Non-existent email returns null.
      final notFound =
          await userRepo.findSuspendedByEmail('nobody@beerer.app');
      expect(notFound, isNull);
    });

    // -----------------------------------------------------------------
    // 6. Re-register with same email → relink old data to new UID
    // -----------------------------------------------------------------
    testWidgets('re-register relinks pours, sessions, and joint accounts',
        (tester) async {
      const newUserId = 'user-new-456';

      // ---- Setup: create user, create session, pour beer ----
      await userRepo.createOrUpdateUser(const AppUser(
        id: userId,
        nickname: userNickname,
        email: userEmail,
        weightKg: 75.0,
        age: 28,
        gender: 'male',
        authProvider: 'email',
      ));

      // Create a keg session where the user is creator and participant.
      final session = await kegRepo.createSession(const KegSession(
        id: '',
        creatorId: userId,
        beerName: 'Relink Pilsner',
        volumeTotalMl: 50000,
        volumeRemainingMl: 50000,
        kegPrice: 80.0,
        alcoholPercent: 5.0,
        predefinedVolumesMl: [500],
        status: KegStatus.created,
      ));
      await kegRepo.addParticipant(session.id, userId);
      await kegRepo.tapKeg(session.id);

      // Pour some beer.
      final pour = await kegRepo.addPour(Pour(
        id: '',
        sessionId: session.id,
        userId: userId,
        pouredById: userId,
        volumeMl: 500,
        timestamp: DateTime.now(),
      ));
      expect(pour.id, isNotEmpty);

      // Create a joint account where the user is a member.
      await fakeFirestore.collection('jointAccounts').doc('ja-1').set({
        'session_id': session.id,
        'group_name': 'The Gang',
        'creator_id': userId,
        'member_user_ids': [userId],
      });

      // ---- Soft-delete the original account ----
      await userRepo.softDeleteUser(userId);

      // Verify suspended.
      final suspended = await userRepo.findSuspendedByEmail(userEmail);
      expect(suspended, isNotNull);
      expect(suspended!.id, userId);

      // ---- Re-register with a new UID (simulates Firebase Auth) ----
      await userRepo.relinkSuspendedAccount(
        oldUserId: userId,
        newUserId: newUserId,
        nickname: 'Alice Reborn',
        email: userEmail,
        weightKg: 70.0,
        age: 29,
        gender: 'female',
      );

      // ---- Verify the new user doc ----
      final newUser = await userRepo.getUser(newUserId);
      expect(newUser, isNotNull);
      expect(newUser!.nickname, 'Alice Reborn');
      expect(newUser.email, userEmail);
      expect(newUser.suspended, false);
      expect(newUser.weightKg, 70.0);

      // Old user doc should be deleted.
      final oldUser = await userRepo.getUser(userId);
      expect(oldUser, isNull);

      // ---- Verify pours reassigned ----
      final pourDoc =
          await fakeFirestore.collection('pours').doc(pour.id).get();
      expect(pourDoc.data()!['user_id'], newUserId);
      expect(pourDoc.data()!['poured_by_id'], newUserId);

      // ---- Verify session participant_ids updated ----
      final sessionDoc = await fakeFirestore
          .collection('kegSessions')
          .doc(session.id)
          .get();
      final participants =
          (sessionDoc.data()!['participant_ids'] as List<dynamic>)
              .cast<String>();
      expect(participants, contains(newUserId));
      expect(participants, isNot(contains(userId)));

      // ---- Verify session creator_id updated ----
      expect(sessionDoc.data()!['creator_id'], newUserId);

      // ---- Verify joint account updated ----
      final jaDoc =
          await fakeFirestore.collection('jointAccounts').doc('ja-1').get();
      expect(jaDoc.data()!['creator_id'], newUserId);
      final jaMembers =
          (jaDoc.data()!['member_user_ids'] as List<dynamic>).cast<String>();
      expect(jaMembers, contains(newUserId));
      expect(jaMembers, isNot(contains(userId)));
    });

    // -----------------------------------------------------------------
    // 7. Re-register with different email → no relink
    // -----------------------------------------------------------------
    testWidgets('re-register with different email does not relink',
        (tester) async {
      const newUserId = 'user-different-789';

      // Create and soft-delete.
      await userRepo.createOrUpdateUser(const AppUser(
        id: userId,
        nickname: userNickname,
        email: userEmail,
        weightKg: 75.0,
        age: 28,
        gender: 'male',
        authProvider: 'email',
      ));
      await userRepo.softDeleteUser(userId);

      // New user registers with a DIFFERENT email.
      final suspended =
          await userRepo.findSuspendedByEmail('other@beerer.app');
      expect(suspended, isNull);

      // The old suspended account should remain untouched.
      final oldUser = await userRepo.getUser(userId);
      expect(oldUser, isNotNull);
      expect(oldUser!.suspended, true);

      // New user can create their own fresh profile.
      await userRepo.createOrUpdateUser(const AppUser(
        id: newUserId,
        nickname: 'Bob',
        email: 'other@beerer.app',
        weightKg: 80.0,
        age: 30,
        gender: 'male',
        authProvider: 'email',
      ));
      final newUser = await userRepo.getUser(newUserId);
      expect(newUser, isNotNull);
      expect(newUser!.nickname, 'Bob');
    });

    // -----------------------------------------------------------------
    // 8. Full lifecycle: register → pour → delete → re-register → verify
    // -----------------------------------------------------------------
    testWidgets('full account lifecycle end-to-end', (tester) async {
      const originalUid = 'lifecycle-uid-1';
      const reRegUid = 'lifecycle-uid-2';
      const email = 'lifecycle@beerer.app';

      // -- Register --
      await userRepo.createOrUpdateUser(const AppUser(
        id: originalUid,
        nickname: 'Lifecycle User',
        email: email,
        weightKg: 80.0,
        age: 30,
        gender: 'male',
        authProvider: 'email',
      ));

      // -- Create session & pour --
      final session = await kegRepo.createSession(const KegSession(
        id: '',
        creatorId: originalUid,
        beerName: 'Lifecycle Lager',
        volumeTotalMl: 30000,
        volumeRemainingMl: 30000,
        kegPrice: 60.0,
        alcoholPercent: 4.5,
        predefinedVolumesMl: [500, 300],
        status: KegStatus.created,
      ));
      await kegRepo.addParticipant(session.id, originalUid);
      await kegRepo.tapKeg(session.id);

      final pour1 = await kegRepo.addPour(Pour(
        id: '',
        sessionId: session.id,
        userId: originalUid,
        pouredById: originalUid,
        volumeMl: 500,
        timestamp: DateTime.now(),
      ));
      final pour2 = await kegRepo.addPour(Pour(
        id: '',
        sessionId: session.id,
        userId: originalUid,
        pouredById: originalUid,
        volumeMl: 300,
        timestamp: DateTime.now(),
      ));

      // Verify keg volume.
      final afterPours = await kegRepo.getSession(session.id);
      expect(afterPours!.volumeRemainingMl, 29200);

      // -- Delete account --
      await userRepo.softDeleteUser(originalUid);

      final deletedUser = await userRepo.getUser(originalUid);
      expect(deletedUser!.suspended, true);
      expect(deletedUser.displayName, 'Deleted User');

      // Pours should still exist (data preserved for other participants).
      final pour1Doc =
          await fakeFirestore.collection('pours').doc(pour1.id).get();
      expect(pour1Doc.exists, true);
      expect(pour1Doc.data()!['user_id'], originalUid);

      // -- Re-register with same email --
      final suspended = await userRepo.findSuspendedByEmail(email);
      expect(suspended, isNotNull);

      await userRepo.relinkSuspendedAccount(
        oldUserId: originalUid,
        newUserId: reRegUid,
        nickname: 'Lifecycle Reborn',
        email: email,
        weightKg: 85.0,
        age: 31,
        gender: 'male',
      );

      // -- Verify relinked state --
      // New profile.
      final newUser = await userRepo.getUser(reRegUid);
      expect(newUser, isNotNull);
      expect(newUser!.nickname, 'Lifecycle Reborn');
      expect(newUser.suspended, false);

      // Old profile gone.
      final oldUser = await userRepo.getUser(originalUid);
      expect(oldUser, isNull);

      // Pours reassigned.
      final p1 =
          await fakeFirestore.collection('pours').doc(pour1.id).get();
      expect(p1.data()!['user_id'], reRegUid);
      final p2 =
          await fakeFirestore.collection('pours').doc(pour2.id).get();
      expect(p2.data()!['user_id'], reRegUid);

      // Session updated.
      final sessionDoc = await fakeFirestore
          .collection('kegSessions')
          .doc(session.id)
          .get();
      expect(sessionDoc.data()!['creator_id'], reRegUid);
      final parts =
          (sessionDoc.data()!['participant_ids'] as List<dynamic>)
              .cast<String>();
      expect(parts, contains(reRegUid));
      expect(parts, isNot(contains(originalUid)));

      // Keg volume unchanged (delete/relink don't affect volume).
      expect(sessionDoc.data()!['volume_remaining_ml'], 29200);

      // No suspended account should remain for this email.
      final noSuspended = await userRepo.findSuspendedByEmail(email);
      expect(noSuspended, isNull);
    });

    // -----------------------------------------------------------------
    // 9. Minimal profile creation fallback
    // -----------------------------------------------------------------
    testWidgets('createMinimalProfile creates profile with only name/email',
        (tester) async {
      const uid = 'minimal-user';
      await userRepo.createMinimalProfile(
        uid: uid,
        nickname: 'Minimal',
        email: 'minimal@beerer.app',
      );

      final user = await userRepo.getUser(uid);
      expect(user, isNotNull);
      expect(user!.nickname, 'Minimal');
      expect(user.email, 'minimal@beerer.app');
      // Default values should apply for unset fields.
      expect(user.suspended, false);
    });

    // -----------------------------------------------------------------
    // 10. Deleting non-existent user throws
    // -----------------------------------------------------------------
    testWidgets('softDeleteUser on missing doc fails gracefully',
        (tester) async {
      // Calling softDeleteUser on a doc that doesn't exist will throw
      // because Firestore update() requires the doc to exist.
      expect(
        () => userRepo.softDeleteUser('nonexistent-id'),
        throwsA(anything),
      );
    });
  });
}
