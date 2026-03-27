// Diagnostic test: mimics the EXACT production widget tree structure
// including ConsumerStatefulWidget, ListView, timer rebuilds, and
// multi-step Firestore update simulation.
import 'dart:async';

import 'package:beerer/widgets/animated_reorderable_column.dart';
import 'package:beerer/widgets/animated_rolling_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mimics _UnifiedParticipantRow — a StatelessWidget that uses AnimatedRollingText.
class _FakeParticipantRow extends StatelessWidget {
  const _FakeParticipantRow({
    super.key,
    required this.name,
    required this.beerCount,
    required this.cost,
    required this.timerText,
  });
  final String name;
  final String beerCount;
  final String cost;
  final String timerText;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              child: AnimatedRollingText(
                text: '#1',
                style: TextStyle(fontSize: 10),
                duration: Duration(milliseconds: 300),
              ),
            ),
            const SizedBox(width: 4),
            Text(name),
            const SizedBox(width: 8),
            const Icon(Icons.sports_bar_outlined, size: 14),
            const SizedBox(width: 3),
            AnimatedRollingText(
              text: beerCount,
              style: const TextStyle(fontSize: 12),
              duration: const Duration(milliseconds: 300),
            ),
            const SizedBox(width: 8),
            AnimatedRollingText(
              text: cost,
              style: const TextStyle(fontSize: 12),
              duration: const Duration(milliseconds: 300),
            ),
            const SizedBox(width: 8),
            // Timer text is plain (changes every second, no animation)
            Text(timerText),
          ],
        ),
      ),
    );
  }
}

class _ParticipantData {
  _ParticipantData({
    required this.id,
    required this.name,
    required this.beerCount,
    required this.cost,
    required this.timerText,
  });
  final String id;
  final String name;
  final String beerCount;
  final String cost;
  final String timerText;
}

/// Mimics _ParticipantsSection — a StatefulWidget wrapping AnimatedReorderableColumn.
/// Uses StatefulWidget (not ConsumerStatefulWidget) for testability.
class _FakeParticipantsSection extends StatefulWidget {
  const _FakeParticipantsSection({
    required this.participants,
  });
  final List<_ParticipantData> participants;

  @override
  State<_FakeParticipantsSection> createState() =>
      _FakeParticipantsSectionState();
}

class _FakeParticipantsSectionState extends State<_FakeParticipantsSection> {
  @override
  Widget build(BuildContext context) {
    final orderedKeys = [
      for (final p in widget.participants) 'p_${p.id}',
    ];
    final lookup = {
      for (final p in widget.participants) 'p_${p.id}': p,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Participants'),
        const SizedBox(height: 8),
        AnimatedReorderableColumn(
          itemKeys: orderedKeys,
          duration: const Duration(milliseconds: 300),
          itemBuilder: (key) {
            final p = lookup[key]!;
            return _FakeParticipantRow(
              key: ValueKey(key),
              name: p.name,
              beerCount: p.beerCount,
              cost: p.cost,
              timerText: p.timerText,
            );
          },
        ),
      ],
    );
  }
}

/// Mimics _ActiveBody — a StatefulWidget with a 1-second timer that calls
/// setState every second, exactly like production code.
class _FakeActiveBody extends StatefulWidget {
  const _FakeActiveBody({
    required this.participants,
    required this.volumeRemaining,
  });
  final List<_ParticipantData> participants;
  final double volumeRemaining;

  @override
  State<_FakeActiveBody> createState() => _FakeActiveBodyState();
}

class _FakeActiveBodyState extends State<_FakeActiveBody> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // 1-second timer, exactly like production _ActiveBodyState
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('active_body_list'),
      padding: const EdgeInsets.all(16),
      children: [
        // Keg level card (simplified)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Remaining: ${widget.volumeRemaining} ml'),
          ),
        ),
        const SizedBox(height: 16),
        // Participants section
        _FakeParticipantsSection(participants: widget.participants),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Mimics _KegDetailBody — the outermost StatefulWidget that receives
/// changing session + pours from the provider layer.
class _FakeKegDetailBody extends StatefulWidget {
  const _FakeKegDetailBody({
    required this.participants,
    required this.volumeRemaining,
  });
  final List<_ParticipantData> participants;
  final double volumeRemaining;

  @override
  State<_FakeKegDetailBody> createState() => _FakeKegDetailBodyState();
}

class _FakeKegDetailBodyState extends State<_FakeKegDetailBody> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Beer')),
      body: _FakeActiveBody(
        participants: widget.participants,
        volumeRemaining: widget.volumeRemaining,
      ),
    );
  }
}

void main() {
  group('Production-like animation diagnostic', () {
    testWidgets(
        'AnimatedRollingText animates after timer ticks + data change',
        (tester) async {
      // -- Initial state --
      var participants = [
        _ParticipantData(id: 'u1', name: 'Alice', beerCount: '1.0', cost: '€2', timerText: '0:05'),
        _ParticipantData(id: 'u2', name: 'Bob', beerCount: '0.5', cost: '€1', timerText: '0:10'),
      ];
      var volume = 4500.0;

      await tester.pumpWidget(MaterialApp(
        home: _FakeKegDetailBody(participants: participants, volumeRemaining: volume),
      ));
      await tester.pumpAndSettle();

      expect(find.text('1.0'), findsOneWidget);
      expect(find.text('0.5'), findsOneWidget);

      // -- Simulate 5 timer ticks (same data, timer-only rebuilds) --
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // Everything should still be stable.
      expect(find.text('1.0'), findsOneWidget);
      expect(find.text('0.5'), findsOneWidget);

      // -- Simulate a pour: volume changes first (session stream arrives first) --
      volume = 4000.0;
      // Same pours — session updated but pours not yet.
      await tester.pumpWidget(MaterialApp(
        home: _FakeKegDetailBody(participants: participants, volumeRemaining: volume),
      ));
      await tester.pump(const Duration(milliseconds: 50));

      // Still old beer counts.
      expect(find.text('1.0'), findsOneWidget);
      expect(find.text('0.5'), findsOneWidget);

      // -- Now pours stream arrives: Alice has 2.0 beers, cost €4 --
      participants = [
        _ParticipantData(id: 'u1', name: 'Alice', beerCount: '2.0', cost: '€4', timerText: '0:00'),
        _ParticipantData(id: 'u2', name: 'Bob', beerCount: '0.5', cost: '€1', timerText: '0:15'),
      ];
      await tester.pumpWidget(MaterialApp(
        home: _FakeKegDetailBody(participants: participants, volumeRemaining: volume),
      ));

      // Pump a few frames into the animation.
      await tester.pump(const Duration(milliseconds: 100));

      // CRITICAL: Both old and new values should coexist during animation.
      expect(find.text('1.0'), findsOneWidget,
          reason: 'Old beer count visible during rolling animation');
      expect(find.text('2.0'), findsOneWidget,
          reason: 'New beer count visible during rolling animation');
      expect(find.text('€2'), findsOneWidget,
          reason: 'Old cost visible during rolling animation');
      expect(find.text('€4'), findsOneWidget,
          reason: 'New cost visible during rolling animation');

      // After settle, only new values.
      await tester.pumpAndSettle();
      expect(find.text('1.0'), findsNothing);
      expect(find.text('2.0'), findsOneWidget);
      expect(find.text('€2'), findsNothing);
      expect(find.text('€4'), findsOneWidget);
    });

    testWidgets(
        'Reorder animation fires after timer ticks + rank change',
        (tester) async {
      // Alice #1, Bob #2.
      var participants = [
        _ParticipantData(id: 'u1', name: 'Alice', beerCount: '1.0', cost: '€2', timerText: '0:05'),
        _ParticipantData(id: 'u2', name: 'Bob', beerCount: '0.5', cost: '€1', timerText: '0:10'),
      ];
      var volume = 4500.0;

      await tester.pumpWidget(MaterialApp(
        home: _FakeKegDetailBody(participants: participants, volumeRemaining: volume),
      ));
      await tester.pumpAndSettle();

      // 5 timer ticks.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // Bob surpasses Alice → reorder: Bob first.
      participants = [
        _ParticipantData(id: 'u2', name: 'Bob', beerCount: '3.0', cost: '€6', timerText: '0:00'),
        _ParticipantData(id: 'u1', name: 'Alice', beerCount: '1.0', cost: '€2', timerText: '0:10'),
      ];
      volume = 3250.0;

      await tester.pumpWidget(MaterialApp(
        home: _FakeKegDetailBody(participants: participants, volumeRemaining: volume),
      ));

      // During animation: verify Transform offsets.
      await tester.pump(const Duration(milliseconds: 100));

      final transforms = tester.widgetList<Transform>(find.byType(Transform));
      var hasNonZeroOffset = false;
      for (final t in transforms) {
        final dy = t.transform.getTranslation().y;
        if (dy.abs() > 0.1) {
          hasNonZeroOffset = true;
          break;
        }
      }
      expect(hasNonZeroOffset, isTrue,
          reason: 'Reorder should produce visible Transform.translate offsets');

      await tester.pumpAndSettle();

      // Bob should be above Alice.
      final bobPos = tester.getTopLeft(find.text('Bob'));
      final alicePos = tester.getTopLeft(find.text('Alice'));
      expect(bobPos.dy, lessThan(alicePos.dy));
    });

    testWidgets(
        'AnimatedSwitcher state survives timer-driven rebuilds in ListView',
        (tester) async {
      // This test verifies that AnimatedSwitcher's internal state
      // (which tracks previous children) persists across the 1-second
      // timer rebuilds from _FakeActiveBodyState.

      var participants = [
        _ParticipantData(id: 'u1', name: 'Alice', beerCount: '1.0', cost: '€2', timerText: '0:05'),
      ];

      await tester.pumpWidget(MaterialApp(
        home: _FakeKegDetailBody(participants: participants, volumeRemaining: 5000),
      ));
      await tester.pumpAndSettle();

      // Let the timer tick 3 times (rebuilds _FakeActiveBody.build() 3 times).
      // The AnimatedSwitcher state should survive these rebuilds.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Now change the beer count → animation should fire.
      participants = [
        _ParticipantData(id: 'u1', name: 'Alice', beerCount: '2.0', cost: '€4', timerText: '0:00'),
      ];

      await tester.pumpWidget(MaterialApp(
        home: _FakeKegDetailBody(participants: participants, volumeRemaining: 4500),
      ));

      // During animation: both old and new should be present.
      await tester.pump(const Duration(milliseconds: 100));

      final allTexts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();

      expect(allTexts.contains('1.0'), isTrue,
          reason: 'Old value should be visible during animation (AnimatedSwitcher state survived timer rebuilds)');
      expect(allTexts.contains('2.0'), isTrue,
          reason: 'New value should be sliding in during animation');

      await tester.pumpAndSettle();
      expect(find.text('1.0'), findsNothing);
      expect(find.text('2.0'), findsOneWidget);
    });
  });
}
