import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/models/models.dart';
import 'package:beerer/screens/keg/participant_detail_screen.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/format_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper to wrap [ParticipantDetailScreen] in a minimal app shell.
Widget _buildTestApp({
  required AppUser user,
  required KegSession session,
  required List<Pour> pours,
  bool isMe = false,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: buildBeerTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: ParticipantDetailScreen(
        user: user,
        session: session,
        pours: pours,
        isMe: isMe,
        prefs: const FormatPreferences(),
      ),
    ),
  );
}

void main() {
  final now = DateTime.now();
  final session = KegSession(
    id: 'session1',
    creatorId: 'creator',
    beerName: 'Test Beer',
    volumeTotalMl: 30000,
    volumeRemainingMl: 29500,
    kegPrice: 100,
    alcoholPercent: 5.0,
    predefinedVolumesMl: const [500],
    status: KegStatus.active,
    startTime: now.subtract(const Duration(hours: 1)),
  );

  final pours = [
    Pour(
      id: 'p1',
      sessionId: 'session1',
      userId: 'user1',
      pouredById: 'user1',
      volumeMl: 500,
      timestamp: now.subtract(const Duration(minutes: 30)),
    ),
  ];

  group('Privacy settings on ParticipantDetailScreen', () {
    testWidgets('stats card is visible when show_stats is true',
        (tester) async {
      const user = AppUser(
        id: 'user1',
        nickname: 'Test User',
        weightKg: 80,
        age: 30,
        gender: 'male',
        preferences: {'show_stats': true, 'show_bac': true},
      );

      await tester.pumpWidget(_buildTestApp(
        user: user,
        session: session,
        pours: pours,
      ));
      await tester.pumpAndSettle();

      // Stats card should be present
      expect(find.text('STATS'), findsOneWidget);
    });

    testWidgets('stats card is hidden when show_stats is false',
        (tester) async {
      const user = AppUser(
        id: 'user1',
        nickname: 'Test User',
        weightKg: 80,
        age: 30,
        gender: 'male',
        preferences: {'show_stats': false, 'show_bac': false},
      );

      await tester.pumpWidget(_buildTestApp(
        user: user,
        session: session,
        pours: pours,
      ));
      await tester.pumpAndSettle();

      // Stats card should be absent
      expect(find.text('STATS'), findsNothing);
    });

    testWidgets('stats are always visible when isMe is true',
        (tester) async {
      const user = AppUser(
        id: 'user1',
        nickname: 'Test User',
        weightKg: 80,
        age: 30,
        gender: 'male',
        preferences: {'show_stats': false, 'show_bac': false},
      );

      await tester.pumpWidget(_buildTestApp(
        user: user,
        session: session,
        pours: pours,
        isMe: true,
      ));
      await tester.pumpAndSettle();

      // Stats should still be visible because isMe overrides
      expect(find.text('STATS'), findsOneWidget);
    });

    testWidgets('personal info hidden when show_personal_info is false',
        (tester) async {
      const user = AppUser(
        id: 'user1',
        nickname: 'Test User',
        weightKg: 80,
        age: 30,
        gender: 'male',
        preferences: {
          'show_stats': true,
          'show_bac': true,
          'show_personal_info': false,
        },
      );

      await tester.pumpWidget(_buildTestApp(
        user: user,
        session: session,
        pours: pours,
      ));
      await tester.pumpAndSettle();

      // Weight/gender line should not appear
      expect(find.text('80 kg · Male'), findsNothing);
    });

    testWidgets('personal info visible when show_personal_info is true',
        (tester) async {
      const user = AppUser(
        id: 'user1',
        nickname: 'Test User',
        weightKg: 80,
        age: 30,
        gender: 'male',
        preferences: {
          'show_stats': true,
          'show_bac': true,
          'show_personal_info': true,
        },
      );

      await tester.pumpWidget(_buildTestApp(
        user: user,
        session: session,
        pours: pours,
      ));
      await tester.pumpAndSettle();

      // Weight/gender line should appear
      expect(find.text('80 kg · Male'), findsOneWidget);
    });

    testWidgets('BAC chart hidden when show_bac is false', (tester) async {
      const user = AppUser(
        id: 'user1',
        nickname: 'Test User',
        weightKg: 80,
        age: 30,
        gender: 'male',
        preferences: {
          'show_stats': true,
          'show_bac': false,
        },
      );

      await tester.pumpWidget(_buildTestApp(
        user: user,
        session: session,
        pours: pours,
      ));
      await tester.pumpAndSettle();

      // BAC chart heading should not appear
      expect(find.text('ESTIMATED BAC OVER TIME'), findsNothing);
    });

    testWidgets('BAC visible when isMe even if show_bac is false',
        (tester) async {
      const user = AppUser(
        id: 'user1',
        nickname: 'Test User',
        weightKg: 80,
        age: 30,
        gender: 'male',
        preferences: {
          'show_stats': false,
          'show_bac': false,
        },
      );

      await tester.pumpWidget(_buildTestApp(
        user: user,
        session: session,
        pours: pours,
        isMe: true,
      ));
      await tester.pump();
      await tester.pump();

      // Scroll down to make the BAC section visible in case lazy ListView
      // hasn't built it yet.
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();

      // BAC chart heading should appear because isMe overrides
      expect(find.text('ESTIMATED BAC OVER TIME'), findsOneWidget);
    });
  });
}
