import 'package:beerer/theme/beer_theme.dart';
import 'package:flutter/material.dart';

/// Participant avatar chip with optional active indicator.
class ParticipantChip extends StatelessWidget {
  const ParticipantChip({
    super.key,
    required this.nickname,
    this.isActive = false,
    this.onTap,
  });

  final String nickname;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: BeerColors.surfaceVariant,
                child: Text(
                  nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                  style:
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: BeerColors.primaryAmber,
                          ),
                ),
              ),
              if (isActive)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: BeerColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: BeerColors.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              nickname,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
