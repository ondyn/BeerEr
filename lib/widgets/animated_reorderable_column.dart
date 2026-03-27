import 'package:flutter/material.dart';

/// A column that implicitly animates the reordering of its children.
///
/// Children are identified by a stable [String] key. When the order
/// changes between builds, rows smoothly slide to their new positions
/// using index-based offset animations.
///
/// Uses per-item [AnimationController]s so each row animates independently.
/// Row height is measured from actual rendered rows via [GlobalKey]s,
/// falling back to an estimate when measurements aren't available yet.
class AnimatedReorderableColumn extends StatefulWidget {
  const AnimatedReorderableColumn({
    super.key,
    required this.itemKeys,
    required this.itemBuilder,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeInOutCubic,
    this.estimatedRowHeight = 72.0,
  });

  /// Ordered list of unique keys, one per item.
  final List<String> itemKeys;

  /// Builds the widget for a given key.
  final Widget Function(String key) itemBuilder;

  /// Animation duration for reorder transitions.
  final Duration duration;

  /// Animation curve for reorder transitions.
  final Curve curve;

  /// Fallback row height when measurement isn't available yet.
  final double estimatedRowHeight;

  @override
  State<AnimatedReorderableColumn> createState() =>
      _AnimatedReorderableColumnState();
}

class _AnimatedReorderableColumnState extends State<AnimatedReorderableColumn>
    with TickerProviderStateMixin {
  /// Maps each key → its GlobalKey for measuring row height.
  final Map<String, GlobalKey> _rowKeys = {};

  /// Per-item Y offset that decays from startPixelDelta → 0.
  /// Non-zero only while the item's controller is animating.
  final Map<String, double> _currentOffsets = {};

  /// Per-item animation controllers for reorder slide animations.
  final Map<String, AnimationController> _controllers = {};

  /// Per-item curved animations.
  final Map<String, CurvedAnimation> _curvedAnimations = {};

  /// The pixel delta each item starts animating from.
  final Map<String, double> _startDeltas = {};

  /// Keys from the previous build, used to detect reordering.
  List<String> _previousKeys = [];

  /// Keys that were just added (not in previous build).
  final Set<String> _newKeys = {};

  /// Per-item fade-in controller for newly added items.
  final Map<String, AnimationController> _fadeControllers = {};
  final Map<String, CurvedAnimation> _fadeAnimations = {};

  @override
  void initState() {
    super.initState();
    _previousKeys = List.of(widget.itemKeys);
    _ensureRowKeys();
  }

  @override
  void didUpdateWidget(AnimatedReorderableColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureRowKeys();

    // Build index lookup for previous order.
    final previousIndexOf = <String, int>{};
    for (var i = 0; i < _previousKeys.length; i++) {
      previousIndexOf[_previousKeys[i]] = i;
    }

    // Build index lookup for new order.
    final newIndexOf = <String, int>{};
    for (var i = 0; i < widget.itemKeys.length; i++) {
      newIndexOf[widget.itemKeys[i]] = i;
    }

    // Detect newly added keys.
    final previousSet = _previousKeys.toSet();
    _newKeys.clear();
    for (final key in widget.itemKeys) {
      if (!previousSet.contains(key)) {
        _newKeys.add(key);
      }
    }

    // Calculate average row height from measured rows.
    final avgHeight = _averageRowHeight();

    for (final key in widget.itemKeys) {
      if (_newKeys.contains(key)) {
        // Animate new items: fade + slide in.
        _disposeFadeController(key);
        final fc = AnimationController(
          vsync: this,
          duration: widget.duration,
        );
        _fadeControllers[key] = fc;
        _fadeAnimations[key] = CurvedAnimation(
          parent: fc,
          curve: widget.curve,
        );
        fc.addListener(() {
          if (mounted) setState(() {});
        });
        fc.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _disposeFadeController(key);
            _newKeys.remove(key);
          }
        });
        fc.forward();
        continue;
      }

      final oldIdx = previousIndexOf[key];
      final newIdx = newIndexOf[key];
      if (oldIdx == null || newIdx == null) continue;

      final indexDelta = oldIdx - newIdx;
      if (indexDelta == 0) continue;

      final pixelDelta = indexDelta * avgHeight;

      // Dispose previous controller for this key if still active.
      _disposeReorderController(key);

      final controller = AnimationController(
        vsync: this,
        duration: widget.duration,
      );
      _controllers[key] = controller;

      final curved = CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      );
      _curvedAnimations[key] = curved;
      _startDeltas[key] = pixelDelta;
      _currentOffsets[key] = pixelDelta;

      // Update offset every frame.
      controller.addListener(() {
        if (mounted) {
          final start = _startDeltas[key] ?? 0;
          _currentOffsets[key] = start * (1.0 - curved.value);
          setState(() {});
        }
      });

      // Clean up when done.
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _disposeReorderController(key);
          _currentOffsets.remove(key);
          _startDeltas.remove(key);
        }
      });

      controller.forward();
    }

    // Clean up controllers for keys that are no longer present.
    final currentKeySet = widget.itemKeys.toSet();
    for (final k in _controllers.keys.toList()) {
      if (!currentKeySet.contains(k)) {
        _disposeReorderController(k);
        _currentOffsets.remove(k);
        _startDeltas.remove(k);
      }
    }
    for (final k in _fadeControllers.keys.toList()) {
      if (!currentKeySet.contains(k)) {
        _disposeFadeController(k);
      }
    }

    _previousKeys = List.of(widget.itemKeys);
  }

  void _disposeReorderController(String key) {
    _curvedAnimations.remove(key)?.dispose();
    _controllers.remove(key)?.dispose();
  }

  void _disposeFadeController(String key) {
    _fadeAnimations.remove(key)?.dispose();
    _fadeControllers.remove(key)?.dispose();
  }

  @override
  void dispose() {
    for (final key in _controllers.keys.toList()) {
      _disposeReorderController(key);
    }
    for (final key in _fadeControllers.keys.toList()) {
      _disposeFadeController(key);
    }
    super.dispose();
  }

  void _ensureRowKeys() {
    for (final key in widget.itemKeys) {
      _rowKeys.putIfAbsent(key, () => GlobalKey());
    }
    // Clean up keys for removed items.
    final currentKeySet = widget.itemKeys.toSet();
    _rowKeys.removeWhere((k, _) => !currentKeySet.contains(k));
  }

  /// Measures actual row heights from rendered GlobalKeys and returns
  /// the average. Falls back to [widget.estimatedRowHeight] if no
  /// rows are measured yet.
  double _averageRowHeight() {
    var totalHeight = 0.0;
    var count = 0;
    for (final gk in _rowKeys.values) {
      final ro = gk.currentContext?.findRenderObject();
      if (ro is RenderBox && ro.hasSize) {
        totalHeight += ro.size.height;
        count++;
      }
    }
    return count > 0 ? totalHeight / count : widget.estimatedRowHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final key in widget.itemKeys) _buildAnimatedRow(key),
      ],
    );
  }

  Widget _buildAnimatedRow(String key) {
    final Widget child = KeyedSubtree(
      key: _rowKeys[key],
      child: widget.itemBuilder(key),
    );

    // Newly added items: fade + slide in from below.
    if (_newKeys.contains(key)) {
      final fadeAnim = _fadeAnimations[key];
      final progress = fadeAnim?.value ?? 1.0;
      return Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 20 * (1.0 - progress)),
          child: child,
        ),
      );
    }

    // Reordering items: slide from old position to new.
    final offset = _currentOffsets[key];
    if (offset != null && offset.abs() > 0.5) {
      return Transform.translate(
        offset: Offset(0, offset),
        child: child,
      );
    }

    return child;
  }
}
