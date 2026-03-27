import 'package:beerer/widgets/animated_rolling_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnimatedRollingText', () {
    testWidgets('displays initial text immediately', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedRollingText(
              text: '3',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('animates when text changes — old and new text coexist during transition', (tester) async {
      // Start with value '1'.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedRollingText(
              text: '1',
              style: TextStyle(fontSize: 14),
              duration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsNothing);

      // Change to value '2'.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedRollingText(
              text: '2',
              style: TextStyle(fontSize: 14),
              duration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      // Pump a few frames into the animation (not to completion).
      await tester.pump(const Duration(milliseconds: 100));

      // Both old and new text should be present during the animation.
      expect(find.text('1'), findsOneWidget, reason: 'Old text should still be visible during animation');
      expect(find.text('2'), findsOneWidget, reason: 'New text should be sliding in during animation');
    });

    testWidgets('after animation completes, only new text remains', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedRollingText(
              text: 'A',
              style: TextStyle(fontSize: 14),
              duration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      // Change text.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedRollingText(
              text: 'B',
              style: TextStyle(fontSize: 14),
              duration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      // Wait for animation to complete.
      await tester.pumpAndSettle();

      expect(find.text('A'), findsNothing, reason: 'Old text should be gone');
      expect(find.text('B'), findsOneWidget, reason: 'New text should remain');
    });

    testWidgets('no animation when text does not change', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedRollingText(
              text: 'same',
              style: TextStyle(fontSize: 14),
              duration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      // Rebuild with same text.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedRollingText(
              text: 'same',
              style: TextStyle(fontSize: 14),
              duration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Only one Text widget with 'same'.
      expect(find.text('same'), findsOneWidget, reason: 'No duplicate text when value unchanged');
    });

    testWidgets('uses Transform.translate and Opacity during animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedRollingText(
              text: 'X',
              style: TextStyle(fontSize: 14),
              duration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      // Change text to trigger animation.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedRollingText(
              text: 'Y',
              style: TextStyle(fontSize: 14),
              duration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Verify Transform.translate and Opacity are in the tree during animation.
      expect(find.byType(Transform), findsWidgets,
          reason: 'Transform.translate should be used during text change animation');
      expect(find.byType(Opacity), findsWidgets,
          reason: 'Opacity should be used during text change animation');
    });

    testWidgets('survives rapid successive text changes', (tester) async {
      Widget buildWith(String text) {
        return MaterialApp(
          home: Scaffold(
            body: AnimatedRollingText(
              text: text,
              style: const TextStyle(fontSize: 14),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildWith('1'));
      await tester.pumpWidget(buildWith('2'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(buildWith('3'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(buildWith('4'));

      // Wait for all animations to settle.
      await tester.pumpAndSettle();

      // Only the final value should remain.
      expect(find.text('4'), findsOneWidget);
    });
  });
}
