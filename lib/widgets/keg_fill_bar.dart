import 'package:beerer/theme/beer_theme.dart';
import 'package:flutter/material.dart';

/// Animated vertical fill bar styled like a keg silhouette.
class KegFillBar extends StatelessWidget {
  const KegFillBar({
    super.key,
    required this.fillPercent,
    this.height = 200,
    this.width = 80,
    this.showLabel = true,
  });

  /// Fill level from 0.0 to 1.0.
  final double fillPercent;
  final double height;
  final double width;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final clampedFill = fillPercent.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: width,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Background keg shape
              Container(
                decoration: BoxDecoration(
                  color: BeerColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Fill level
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                height: height * clampedFill,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      BeerColors.primaryDark,
                      BeerColors.primaryAmber,
                      Color(0xFFF5ECD7), // foam
                    ],
                    stops: [0.0, 0.85, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 8),
          Text(
            '${(clampedFill * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: BeerColors.primaryAmber,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ],
    );
  }
}
