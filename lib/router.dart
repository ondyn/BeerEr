import 'package:beerer/providers/auth_provider.dart';
import 'package:beerer/screens/screens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

@riverpod
GoRouter router(Ref ref) {
  final authNotifier = _AuthNotifier();
  ref.onDispose(authNotifier.dispose);

  // Listen to the Riverpod auth stream so the provider stays alive,
  // but do NOT recreate the GoRouter on every change.
  ref.listen(authStateProvider, (_, _) {});

  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: '/welcome',
    overridePlatformDefaultLocation: true,
    onException: (context, state, router) {
      final sessionId = _extractExternalJoinSessionId(state.uri);
      if (sessionId != null && sessionId.isNotEmpty) {
        router.go('/join/$sessionId');
        return;
      }

      // Prevent landing on an unresolved route (which can leave users
      // visually stuck on the splash fallback).
      router.go('/welcome');
    },
    refreshListenable: authNotifier,
    redirect: (context, state) async {
      final user = authNotifier.user;
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

      // For logged-in users, gate by profile completeness.
      // This prevents first-time Google sign-in from being redirected to /home
      // before the app can route to /auth/complete-profile.
      if (loggedIn && isAuthRoute) {
        final profileSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final data = profileSnap.data();
        final weightKg = (data?['weight_kg'] as num?)?.toDouble() ?? 0.0;
        final age = (data?['age'] as num?)?.toInt() ?? 0;
        final isProfileComplete = weightKg > 0 && age > 0;

        if (!isProfileComplete && path != '/auth/complete-profile') {
          return '/auth/complete-profile';
        }

        if (isProfileComplete && path == '/auth/complete-profile') {
          return '/home';
        }

        if (isProfileComplete && path != '/auth/complete-profile') {
          return '/home';
        }
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

String? _extractExternalJoinSessionId(Uri uri) {
  if (uri.scheme == 'beerer' && uri.host == 'join') {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  }

  const allowedHttpsHosts = {
    'ondyn-beerer.web.app',
    'ondyn-beerer.firebaseapp.com',
  };
  final isHttpsJoin =
      uri.scheme == 'https' &&
      allowedHttpsHosts.contains(uri.host) &&
      uri.pathSegments.length >= 2 &&
      uri.pathSegments.first == 'join';
  if (isHttpsJoin) {
    return uri.pathSegments[1];
  }

  return null;
}
