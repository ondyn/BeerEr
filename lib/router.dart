import 'package:beerer/providers/auth_provider.dart';
import 'package:beerer/screens/screens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

/// A shared navigator key so [main.dart] can push deep-link routes before
/// the widget tree is ready.
final appNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter router(Ref ref) {
  final authAsync = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: appNavigatorKey,
    // initialLocation: '/', // SKIP SPLASH: was '/', now going straight to /welcome
    initialLocation: '/welcome',
    redirect: (context, state) {
      final user = authAsync.value;
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
      ];
      final isAuthRoute = authPaths.contains(path);

      // Allow join links even when not logged in (they'll auth first)
      final isJoinRoute = path.startsWith('/join/');

      if (!loggedIn && !isAuthRoute && !isJoinRoute) {
        return '/welcome';
      }
      if (loggedIn && isAuthRoute) {
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
          // Step 14: Settle Up route disabled.
          // GoRoute(
          //   path: 'settle',
          //   builder: (context, state) {
          //     final sessionId = state.pathParameters['sessionId']!;
          //     return SettleUpScreen(sessionId: sessionId);
          //   },
          // ),
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
