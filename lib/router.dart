import 'package:beerer/providers/auth_provider.dart';
import 'package:beerer/screens/screens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

/// A shared navigator key so [main.dart] can push deep-link routes before
/// the widget tree is ready.
final appNavigatorKey = GlobalKey<NavigatorState>();

/// A [ChangeNotifier] that wraps the Firebase auth-state stream so
/// [GoRouter.refreshListenable] can trigger a redirect re-evaluation
/// without rebuilding the entire GoRouter (which would reset the
/// navigation stack and lose any in-screen error state).
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  User? _user;
  User? get user => _user;
}

/// Single instance shared by the router provider.
final _authNotifier = _AuthNotifier();

@riverpod
GoRouter router(Ref ref) {
  // Listen to the Riverpod auth stream so the provider stays alive,
  // but do NOT recreate the GoRouter on every change.
  ref.listen(authStateProvider, (_, _) {});

  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: '/welcome',
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final user = _authNotifier.user;
      final emailVerified = user?.emailVerified ?? false;
      final loggedIn = user != null && emailVerified;
      final path = state.uri.path;

      // Allow splash always
      // if (path == '/') return null; // SKIP SPLASH: splash bypassed

      // Allow auth routes when not logged in
      final authPaths = [
        '/welcome',
        '/auth/sign-in',
        '/auth/register',
        '/auth/forgot-password',
        '/auth/complete-profile',
      ];
      final isAuthRoute = authPaths.contains(path);

      // Allow join links even when not logged in (they'll auth first)
      final isJoinRoute = path.startsWith('/join/');

      if (!loggedIn && !isAuthRoute && !isJoinRoute) {
        return '/welcome';
      }
      if (loggedIn && isAuthRoute && path != '/auth/complete-profile') {
        return '/home';
      }
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) =>
            const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/complete-profile',
        builder: (context, state) =>
            const CompleteProfileScreen(),
      ),

      // Main
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Keg
      GoRoute(
        path: '/keg/new',
        builder: (context, state) => const CreateKegScreen(),
      ),
      GoRoute(
        path: '/keg/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return KegDetailScreen(sessionId: sessionId);
        },
        routes: [
          GoRoute(
            path: 'info',
            builder: (context, state) {
              final sessionId =
                  state.pathParameters['sessionId']!;
              return KegInfoScreen(sessionId: sessionId);
            },
          ),
          GoRoute(
            path: 'share',
            builder: (context, state) {
              final sessionId =
                  state.pathParameters['sessionId']!;
              return ShareSessionScreen(
                  sessionId: sessionId);
            },
          ),
          GoRoute(
            path: 'review',
            builder: (context, state) {
              final sessionId =
                  state.pathParameters['sessionId']!;
              return BillReviewScreen(sessionId: sessionId);
            },
          ),
        ],
      ),

      // Join via deep link
      GoRoute(
        path: '/join/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return JoinSessionScreen(sessionId: sessionId);
        },
      ),

      // Profile / Settings / About
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),

      // History
      GoRoute(
        path: '/sessions/history',
        builder: (context, state) => const HistoryScreen(),
      ),
    ],
  );
}
