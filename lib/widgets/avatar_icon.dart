import 'package:beerer/theme/beer_theme.dart';
import 'package:flutter/material.dart';

/// A curated list of Material icon code‑points that users can pick as
/// their avatar.  Each entry is an [IconData] with
/// `fontFamily: 'MaterialIcons'`.
const List<IconData> kAvatarIcons = [
  Icons.sports_bar, // 🍺
  Icons.local_bar, // 🍸
  Icons.wine_bar, // 🍷
  Icons.local_drink, // 🥤
  Icons.emoji_food_beverage, // ☕
  Icons.liquor, // 🥃
  Icons.nightlife, // 🎉
  Icons.celebration, // 🎊
  Icons.music_note, // 🎵
  Icons.headphones, // 🎧
  Icons.pets, // 🐾
  Icons.star, // ⭐
  Icons.favorite, // ❤️
  Icons.bolt, // ⚡
  Icons.whatshot, // 🔥
  Icons.emoji_emotions, // 😊
  Icons.face, // 🙂
  Icons.face_2, // 👤
  Icons.face_3, // 👤
  Icons.face_4, // 👤
  Icons.face_5, // 👤
  Icons.face_6, // 👤
  Icons.cruelty_free, // 🐰
  Icons.park, // 🌲
  Icons.sunny, // ☀️
  Icons.ac_unit, // ❄️
  Icons.rocket_launch, // 🚀
  Icons.anchor, // ⚓
  Icons.directions_bike, // 🚲
  Icons.skateboarding, // 🛹
  Icons.surfing, // 🏄
  Icons.pool, // 🏊
  Icons.sports_soccer, // ⚽
  Icons.sports_basketball, // 🏀
  Icons.sports_tennis, // 🎾
  Icons.sports_esports, // 🎮
  Icons.fitness_center, // 💪
  Icons.self_improvement, // 🧘
  Icons.science, // 🔬
  Icons.palette, // 🎨
];

/// Resolves a stored [codePoint] back to an [IconData].
/// Returns `null` when [codePoint] is `null` or not recognised.
IconData? iconFromCodePoint(int? codePoint) {
  if (codePoint == null) return null;
  return IconData(codePoint, fontFamily: 'MaterialIcons');
}

/// A circle avatar that shows either the chosen Material icon or falls
/// back to the first letter of the given [displayName].
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.displayName,
    this.avatarIcon,
    this.radius = 18,
    this.isHighlighted = false,
  });

  final String displayName;

  /// The Material icon codePoint stored in Firestore, or `null`.
  final int? avatarIcon;

  final double radius;

  /// When `true` the avatar uses the accent colour (primary amber) instead
  /// of the neutral surface variant.
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final icon = iconFromCodePoint(avatarIcon);
    final bg = isHighlighted
        ? BeerColors.primaryAmber
        : BeerColors.surfaceVariant;
    final fg = isHighlighted
        ? BeerColors.background
        : BeerColors.onSurface;

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: icon != null
          ? Icon(icon, size: radius * 1.1, color: fg)
          : Text(
              displayName.isNotEmpty
                  ? displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: radius * 0.8,
              ),
            ),
    );
  }
}

/// A circle avatar for joint accounts / groups.
class GroupAvatarCircle extends StatelessWidget {
  const GroupAvatarCircle({
    super.key,
    this.avatarIcon,
    this.radius = 18,
  });

  final int? avatarIcon;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final icon = iconFromCodePoint(avatarIcon);
    return CircleAvatar(
      radius: radius,
      backgroundColor: BeerColors.surfaceVariant,
      child: Icon(
        icon ?? Icons.group,
        size: radius * 1.1,
        color: BeerColors.primaryAmber,
      ),
    );
  }
}
