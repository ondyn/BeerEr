import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/theme/mono_style.dart';
import 'package:flutter/material.dart';

/// A stat label + value tile using monospaced numbers.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: BeerColors.primaryAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BeerColors.onSurfaceSecondary,
                  ),
            ),
          ),
          Text(
            value,
            style: MonoStyle.number(
              fontSize: 16,
              color: valueColor ?? BeerColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
