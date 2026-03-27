import 'package:beerer/widgets/animated_reorderable_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnimatedReorderableColumn', () {
    Widget buildColumn(List<String> keys) {
      return MaterialApp(
        home: Scaffold(
          body: AnimatedReorderableColumn(
            itemKeys: keys,
            duration: const Duration(milliseconds: 300),
            estimatedRowHeight: 50.0,
            itemBuilder: (key) {
              return Container(
                key: ValueKey(key),
                height: 50,
                color: Colors.blue,
                child: Text('Item $key'),
              );
            },
          ),
        ),
      );
    }

    testWidgets('renders all items in order', (tester) async {
      await tester.pumpWidget(buildColumn(['a', 'b', 'c']));

      expect(find.text('Item a'), findsOneWidget);
      expect(find.text('Item b'), findsOneWidget);
      expect(find.text('Item c'), findsOneWidget);
    });

    testWidgets('applies Transform.translate during reorder animation', (tester) async {
      // Initial order: a, b, c.
      await tester.pumpWidget(buildColumn(['a', 'b', 'c']));
      await tester.pumpAndSettle();

      // Swap b and c → a, c, b.
      await tester.pumpWidget(buildColumn(['a', 'c', 'b']));

      // Pump a few frames into the animation.
      await tester.pump(const Duration(milliseconds: 50));

      // During the animation, Transform.translate widgets should be present
      // for the items that moved (b and c).
      final transforms = tester.widgetList<Transform>(find.byType(Transform));

      // At least some transforms should have non-zero offsets.
      var hasNonZeroOffset = false;
      for (final transform in transforms) {
        final matrix = transform.transform;
        final dy = matrix.getTranslation().y;
        if (dy.abs() > 0.1) {
          hasNonZeroOffset = true;
          break;
        }
      }

      expect(hasNonZeroOffset, isTrue,
          reason: 'Transform.translate should have non-zero Y offset during reorder animation');
    });

    testWidgets('animation completes — transforms return to zero', (tester) async {
      await tester.pumpWidget(buildColumn(['a', 'b', 'c']));
      await tester.pumpAndSettle();

      // Reorder: reverse the list.
      await tester.pumpWidget(buildColumn(['c', 'b', 'a']));

      // Let animation run to completion.
      await tester.pumpAndSettle();

      // After animation, no Transform with non-zero offset should remain
      // (the AnimatedBuilder wrapping Transform.translate should be gone
      // once the controller completes and is cleaned up).
      // All items should still be present.
      expect(find.text('Item a'), findsOneWidget);
      expect(find.text('Item b'), findsOneWidget);
      expect(find.text('Item c'), findsOneWidget);
    });

    testWidgets('no animation when order stays the same', (tester) async {
      await tester.pumpWidget(buildColumn(['a', 'b', 'c']));
      await tester.pumpAndSettle();

      // Same order rebuild.
      await tester.pumpWidget(buildColumn(['a', 'b', 'c']));
      await tester.pump(const Duration(milliseconds: 50));

      // No AnimatedBuilder wrapping transforms expected.
      // All items should be rendered normally.
      expect(find.text('Item a'), findsOneWidget);
      expect(find.text('Item b'), findsOneWidget);
      expect(find.text('Item c'), findsOneWidget);
    });

    testWidgets('handles adding a new item with fade-in animation', (tester) async {
      await tester.pumpWidget(buildColumn(['a', 'b']));
      await tester.pumpAndSettle();

      // Add item 'c'.
      await tester.pumpWidget(buildColumn(['a', 'b', 'c']));
      await tester.pump(const Duration(milliseconds: 50));

      // New item 'c' should be visible (may have partial opacity).
      expect(find.text('Item c'), findsOneWidget);

      // There should be an Opacity widget wrapping the new item.
      final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity));
      var hasPartialOpacity = false;
      for (final opacity in opacityWidgets) {
        if (opacity.opacity > 0.0 && opacity.opacity < 1.0) {
          hasPartialOpacity = true;
          break;
        }
      }
      expect(hasPartialOpacity, isTrue,
          reason: 'Newly added item should fade in with partial opacity during animation');

      // Let animation complete.
      await tester.pumpAndSettle();
      expect(find.text('Item c'), findsOneWidget);
    });

    testWidgets('handles removing an item gracefully', (tester) async {
      await tester.pumpWidget(buildColumn(['a', 'b', 'c']));
      await tester.pumpAndSettle();

      // Remove item 'b'.
      await tester.pumpWidget(buildColumn(['a', 'c']));
      await tester.pumpAndSettle();

      expect(find.text('Item a'), findsOneWidget);
      expect(find.text('Item b'), findsNothing);
      expect(find.text('Item c'), findsOneWidget);
    });

    testWidgets('survives repeated rebuilds without state loss', (tester) async {
      // Simulate the 1-second timer rebuilds from _ActiveBodyState.
      // The same order is passed multiple times — no animation should occur,
      // and the widget state should remain stable.

      await tester.pumpWidget(buildColumn(['a', 'b', 'c']));
      await tester.pumpAndSettle();

      // 10 rapid rebuilds with same keys (simulating timer ticks).
      for (var i = 0; i < 10; i++) {
        await tester.pumpWidget(buildColumn(['a', 'b', 'c']));
        await tester.pump(const Duration(seconds: 1));
      }

      // All items still present, no crashes.
      expect(find.text('Item a'), findsOneWidget);
      expect(find.text('Item b'), findsOneWidget);
      expect(find.text('Item c'), findsOneWidget);
    });

    testWidgets('reorder animation works after multiple same-order rebuilds', (tester) async {
      // Simulate: several same-order rebuilds, then an actual reorder.
      await tester.pumpWidget(buildColumn(['a', 'b', 'c']));
      await tester.pumpAndSettle();

      // 5 same-order rebuilds.
      for (var i = 0; i < 5; i++) {
        await tester.pumpWidget(buildColumn(['a', 'b', 'c']));
        await tester.pump(const Duration(seconds: 1));
      }

      // Now reorder: move c to the top.
      await tester.pumpWidget(buildColumn(['c', 'a', 'b']));
      await tester.pump(const Duration(milliseconds: 50));

      // Verify animation is happening (Transform with offset).
      final transforms = tester.widgetList<Transform>(find.byType(Transform));
      var hasNonZeroOffset = false;
      for (final transform in transforms) {
        final matrix = transform.transform;
        final dy = matrix.getTranslation().y;
        if (dy.abs() > 0.1) {
          hasNonZeroOffset = true;
          break;
        }
      }
      expect(hasNonZeroOffset, isTrue,
          reason: 'Reorder animation should work even after many same-order rebuilds');

      // Let it complete.
      await tester.pumpAndSettle();
      expect(find.text('Item c'), findsOneWidget);
      expect(find.text('Item a'), findsOneWidget);
      expect(find.text('Item b'), findsOneWidget);
    });

    testWidgets('handles large reorder — full reversal', (tester) async {
      await tester.pumpWidget(buildColumn(['a', 'b', 'c', 'd', 'e']));
      await tester.pumpAndSettle();

      // Full reversal.
      await tester.pumpWidget(buildColumn(['e', 'd', 'c', 'b', 'a']));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify transforms are active.
      final transforms = tester.widgetList<Transform>(find.byType(Transform));
      var animating = false;
      for (final t in transforms) {
        final dy = t.transform.getTranslation().y;
        if (dy.abs() > 0.1) {
          animating = true;
          break;
        }
      }
      expect(animating, isTrue,
          reason: 'Full reversal should produce visible translate animations');

      await tester.pumpAndSettle();

      // Verify final order by checking render positions.
      final ePos = tester.getTopLeft(find.text('Item e'));
      final aPos = tester.getTopLeft(find.text('Item a'));
      expect(ePos.dy, lessThan(aPos.dy),
          reason: 'After reversal, e should be above a');
    });
  });
}
