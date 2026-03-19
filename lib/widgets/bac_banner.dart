import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/bac_calculator.dart';
import 'package:beerer/utils/time_formatter.dart';
import 'package:flutter/material.dart';

/// BAC estimate strip with time-to-zero and "Drink Responsibly" note.
class BacBanner extends StatelessWidget {
  const BacBanner({
    super.key,
    required this.bacValue,
  });

  final double bacValue;

  @override
  Widget build(BuildContext context) {
    final timeToZero = BacCalculator.timeToZero(bacValue);

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
          if (timeToZero != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.directions_car,
                  size: 16,
                  color: BeerColors.onSurfaceSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Ready to drive in ~${TimeFormatter.formatDuration(timeToZero)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BeerColors.onSurfaceSecondary,
                      ),
                ),
              ],
            ),
          ],
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
