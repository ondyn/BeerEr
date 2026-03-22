import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/providers/auth_provider.dart';
import 'package:beerer/repositories/joint_account_repository.dart';
import 'package:beerer/repositories/keg_repository.dart';
import 'package:beerer/repositories/pour_repository.dart';
import 'package:beerer/repositories/user_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A mock Firebase user for integration tests.
MockUser get testMockUser => MockUser(
      uid: 'test-user-1',
      email: 'test@beerer.app',
      displayName: 'Test User',
      isEmailVerified: true,
    );

/// A second mock user for multi-participant tests.
MockUser get testMockUser2 => MockUser(
      uid: 'test-user-2',
      email: 'user2@beerer.app',
      displayName: 'User Two',
      isEmailVerified: true,
    );

/// Creates a fully configured test app with fake Firebase services.
///
/// Returns a [TestApp] containing the widget, the [FakeFirebaseFirestore]
/// instance for seeding/asserting data, and the [MockFirebaseAuth].
TestApp createTestApp({
  MockUser? mockUser,
  String initialRoute = '/home',
}) {
  final fakeFirestore = FakeFirebaseFirestore();
  final user = mockUser ?? testMockUser;
  final mockAuth = MockFirebaseAuth(
    mockUser: user,
    signedIn: true,
  );

  // Pre-seed the user document so providers find the profile.
  fakeFirestore.collection('users').doc(user.uid).set({
    'nickname': user.displayName ?? 'Tester',
    'email': user.email ?? '',
    'weight_kg': 80.0,
    'age': 30,
    'gender': 'male',
    'auth_provider': 'email',
    'preferences': <String, dynamic>{},
    'avatar_icon': null,
  });

  final container = ProviderContainer(
    overrides: [
      // Auth
      authStateProvider.overrideWith((ref) {
        return Stream.value(mockAuth.currentUser);
      }),

      // Repositories — injected with fakeFirestore
      kegRepositoryProvider
          .overrideWithValue(KegRepository(fakeFirestore)),
      pourRepositoryProvider
          .overrideWithValue(PourRepository(fakeFirestore)),
      jointAccountRepositoryProvider
          .overrideWithValue(JointAccountRepository(fakeFirestore)),
      userRepositoryProvider
          .overrideWithValue(UserRepository(fakeFirestore)),
    ],
  );

  final router = GoRouter(
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => const _HomeScreen(),
      ),
      GoRoute(
        path: '/keg/new',
        builder: (_, __) => const _Placeholder('Create Keg'),
      ),
      // The actual routes are complex — for integration tests we mostly
      // interact with the app through the real screens via the container.
    ],
  );

  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: buildBeerTheme(),
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );

  return TestApp(
    widget: widget,
    firestore: fakeFirestore,
    auth: mockAuth,
    container: container,
  );
}

/// Bundles everything needed for an integration test.
class TestApp {
  const TestApp({
    required this.widget,
    required this.firestore,
    required this.auth,
    required this.container,
  });

  final Widget widget;
  final FakeFirebaseFirestore firestore;
  final MockFirebaseAuth auth;
  final ProviderContainer container;

  void dispose() {
    container.dispose();
  }
}

/// Placeholder screen for routes not under test.
class _Placeholder extends StatelessWidget {
  const _Placeholder(this.name);
  final String name;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(name)));
}

/// Minimal home screen stand-in.
class _HomeScreen extends StatelessWidget {
  const _HomeScreen();
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Home')));
}
