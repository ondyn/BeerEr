import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:beerer/app.dart';
import 'package:beerer/firebase_options.dart';
import 'package:beerer/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: BeerErApp()));

  // Handle deep links (beerer://join/<sessionId>) after the app is running.
  final appLinks = AppLinks();

  // Initial link when the app is opened cold via a link.
  final initialUri = await appLinks.getInitialLink();
  if (initialUri != null) {
    _handleDeepLink(initialUri);
  }

  // Subsequent links while the app is in foreground / background.
  appLinks.uriLinkStream.listen(_handleDeepLink);
}

/// Translates a `beerer://join/[sessionId]` URI into a GoRouter path.
///
/// URI shape:  beerer://join/[sessionId]
///   scheme  = beerer
///   host    = join
///   path    = /[sessionId]   (pathSegments[0])
void _handleDeepLink(Uri uri) {
  if (uri.scheme != 'beerer' || uri.host != 'join') return;

  final sessionId = uri.pathSegments.isNotEmpty
      ? uri.pathSegments.first
      : null;
  if (sessionId == null || sessionId.isEmpty) return;

  final context = appNavigatorKey.currentContext;
  if (context != null) {
    GoRouter.of(context).go('/join/$sessionId');
  }
}
