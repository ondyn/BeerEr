import 'package:flutter/material.dart';

/// A large CTA button used to log a pour.
class PourButton extends StatelessWidget {
  const PourButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.sports_bar),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
      ),
    );
  }
}
