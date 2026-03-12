import 'package:beerer/theme/beer_theme.dart';
import 'package:flutter/material.dart';

/// BAC estimate strip with "Drink Responsibly" note.
class BacBanner extends StatelessWidget {
  const BacBanner({
    super.key,
    required this.bacValue,
  });

  final double bacValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BeerColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BeerColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.science,
                size: 18,
                color: BeerColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                'Est. BAC: ${bacValue.toStringAsFixed(3)} ‰',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Please drink responsibly.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: BeerColors.onSurfaceSecondary,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}
