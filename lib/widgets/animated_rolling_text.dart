import 'package:flutter/material.dart';

/// A widget that animates text changes with a vertical rolling effect
/// (old text slides up and fades out, new text slides in from below).
///
/// This is a [StatefulWidget] that **explicitly tracks the previous text
/// value** and manages its own [AnimationController]. This makes it fully
/// self-contained — it does NOT depend on any parent's Element or State
/// surviving across rebuilds (unlike an AnimatedSwitcher-based approach).
///
/// Designed for numeric values (beer count, price, rank) but works
/// with any text.
class AnimatedRollingText extends StatefulWidget {
  const AnimatedRollingText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 400),
  });

  /// The current text value to display.
  final String text;

  /// Text style to apply.
  final TextStyle? style;

  /// Duration of the roll animation.
  final Duration duration;

  @override
  State<AnimatedRollingText> createState() => _AnimatedRollingTextState();
}

class _AnimatedRollingTextState extends State<AnimatedRollingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  /// The text value we're transitioning FROM (the old value).
  String? _previousText;

  /// Whether an animation is currently in progress.
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
            _previousText = null;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedRollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      // Text changed — start a rolling animation.
      _previousText = oldWidget.text;
      _isAnimating = true;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAnimating || _previousText == null) {
      // No animation — just show the current text.
      return Text(
        widget.text,
        style: widget.style,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }

    // During animation: show old text sliding up + fading out,
    // and new text sliding in from below + fading in.
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final progress = _animation.value; // 0.0 → 1.0

        return ClipRect(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Old text: slides up, fades out.
              Transform.translate(
                offset: Offset(0, -20 * progress),
                child: Opacity(
                  opacity: (1.0 - progress).clamp(0.0, 1.0),
                  child: Text(
                    _previousText!,
                    style: widget.style,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              // New text: slides in from below, fades in.
              Transform.translate(
                offset: Offset(0, 20 * (1.0 - progress)),
                child: Opacity(
                  opacity: progress.clamp(0.0, 1.0),
                  child: Text(
                    widget.text,
                    style: widget.style,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
