import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test: the pour-confirmation snackbar must auto-dismiss
/// after its designated time, even when the widget tree is being rebuilt
/// every second by a periodic timer (as happens on the active keg screen)
/// AND the parent is rebuilt by provider changes.
///
/// Previously, the snackbar stayed permanently visible because Flutter's
/// built-in SnackBar duration timer got disrupted by the combination of
/// periodic child rebuilds and parent rebuilds.
///
/// The fix uses a manual [Timer] to call `hideCurrentSnackBar()` instead
/// of relying on [SnackBar.duration]. The snackbar is shown with
/// `duration: Duration(days: 1)` (effectively infinite) and a separate
/// `Timer(Duration(seconds: 5), ...)` handles dismissal.
void main() {
  group('Pour snackbar auto-dismiss (manual Timer approach)', () {
    testWidgets(
      'Baseline: manual Timer dismisses a long-duration SnackBar',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Static')),
              body: const Center(child: Text('Hello')),
            ),
          ),
        );

        final messenger = tester.state<ScaffoldMessengerState>(
          find.byType(ScaffoldMessenger),
        );

        // Show a snackbar with effectively infinite built-in duration.
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Pour logged'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(days: 1),
            ),
          );

        // Start the manual dismiss timer (like the production code does).
        Timer(const Duration(seconds: 3), () {
          messenger.hideCurrentSnackBar();
        });

        // Entrance animation.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Pour logged'), findsOneWidget);

        // Advance past the 3-second manual timer.
        await tester.pump(const Duration(seconds: 3));

        // Exit animation.
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Pour logged'), findsNothing);
      },
    );

    testWidgets(
      'SnackBar auto-dismisses with periodic body rebuilds and parent '
      'rebuilds after showing (simulates real keg screen)',
      (WidgetTester tester) async {
        var sessionData = 'volume: 50000';
        late StateSetter outerSetState;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                outerSetState = setState;
                return Scaffold(
                  appBar: AppBar(title: Text(sessionData)),
                  body: const _RebuildingBody(),
                );
              },
            ),
          ),
        );

        final messenger = tester.state<ScaffoldMessengerState>(
          find.byType(ScaffoldMessenger),
        );

        // Show snackbar the same way the production code does.
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Pour logged'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(days: 1),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {},
              ),
            ),
          );

        // Manual timer for dismissal.
        Timer(const Duration(seconds: 3), () {
          messenger.hideCurrentSnackBar();
        });

        // Entrance animation.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Pour logged'), findsOneWidget);
        expect(find.text('Undo'), findsOneWidget);

        // Simulate provider-triggered parent rebuilds (session data changed).
        outerSetState(() => sessionData = 'volume: 49500');
        await tester.pump(const Duration(milliseconds: 50));
        outerSetState(() => sessionData = 'volume: 49500 (pours updated)');
        await tester.pump(const Duration(milliseconds: 50));

        // Snackbar should still be visible.
        expect(find.text('Pour logged'), findsOneWidget);

        // Advance past the 3-second manual timer.
        // (Already consumed ~400ms of entrance + 100ms of parent rebuilds.)
        await tester.pump(const Duration(seconds: 3));

        // Exit animation.
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        // Must be gone.
        expect(find.text('Pour logged'), findsNothing);
      },
    );

    testWidgets(
      'SnackBar disappears when only the body rebuilds periodically',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Static Scaffold')),
              body: const _RebuildingBody(),
            ),
          ),
        );

        final messenger = tester.state<ScaffoldMessengerState>(
          find.byType(ScaffoldMessenger),
        );

        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Pour logged'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(days: 1),
            ),
          );

        Timer(const Duration(seconds: 3), () {
          messenger.hideCurrentSnackBar();
        });

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Pour logged'), findsOneWidget);

        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Pour logged'), findsNothing);
      },
    );

    testWidgets(
      'SnackBar survives a single parent rebuild (simulates provider change)',
      (WidgetTester tester) async {
        var data = 'Before pour';
        late StateSetter outerSetState;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                outerSetState = setState;
                return Scaffold(
                  appBar: AppBar(title: Text(data)),
                  body: Center(child: Text(data)),
                );
              },
            ),
          ),
        );

        final messenger = tester.state<ScaffoldMessengerState>(
          find.byType(ScaffoldMessenger),
        );

        messenger.showSnackBar(
          const SnackBar(
            content: Text('Pour logged'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(days: 1),
          ),
        );

        Timer(const Duration(seconds: 3), () {
          messenger.hideCurrentSnackBar();
        });

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Pour logged'), findsOneWidget);

        // Trigger parent rebuild.
        outerSetState(() => data = 'After pour');
        await tester.pump();
        expect(find.text('Pour logged'), findsOneWidget);

        // Advance past manual timer.
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Pour logged'), findsNothing);
      },
    );

    testWidgets(
      'Tapping Undo dismisses the snackbar and cancels the timer',
      (WidgetTester tester) async {
        var undoPressed = false;
        Timer? dismissTimer;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: const Center(child: Text('Hello')),
            ),
          ),
        );

        final messenger = tester.state<ScaffoldMessengerState>(
          find.byType(ScaffoldMessenger),
        );

        messenger.showSnackBar(
          SnackBar(
            content: const Text('Pour logged'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(days: 1),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                dismissTimer?.cancel();
                undoPressed = true;
              },
            ),
          ),
        );

        dismissTimer = Timer(const Duration(seconds: 5), () {
          messenger.hideCurrentSnackBar();
        });

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Pour logged'), findsOneWidget);

        // Tap Undo.
        await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
        await tester.pumpAndSettle();

        expect(undoPressed, isTrue);
        expect(find.text('Pour logged'), findsNothing);
      },
    );

    testWidgets(
      'Showing a second snackbar replaces the first '
      '(new timer cancels old timer)',
      (WidgetTester tester) async {
        Timer? dismissTimer;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: const _RebuildingBody(),
            ),
          ),
        );

        final messenger = tester.state<ScaffoldMessengerState>(
          find.byType(ScaffoldMessenger),
        );

        void showSnack(String text) {
          dismissTimer?.cancel();
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(text),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(days: 1),
              ),
            );
          dismissTimer = Timer(const Duration(seconds: 3), () {
            messenger.hideCurrentSnackBar();
          });
        }

        // First snackbar.
        showSnack('Pour 1');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Pour 1'), findsOneWidget);

        // After 1 second, show second snackbar (replaces first).
        await tester.pump(const Duration(seconds: 1));
        showSnack('Pour 2');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Pour 2 should be visible; Pour 1 should be gone (or animating out).
        expect(find.text('Pour 2'), findsOneWidget);

        // Advance 3 seconds (full timer for the second snackbar).
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        // Both gone.
        expect(find.text('Pour 1'), findsNothing);
        expect(find.text('Pour 2'), findsNothing);
      },
    );
  });
}

/// A body widget that rebuilds every second via a periodic timer,
/// simulating the live-stat ticker in `_ActiveBody`.
class _RebuildingBody extends StatefulWidget {
  const _RebuildingBody();

  @override
  State<_RebuildingBody> createState() => _RebuildingBodyState();
}

class _RebuildingBodyState extends State<_RebuildingBody> {
  Timer? _ticker;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _count++);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Rebuilds: $_count'));
  }
}
