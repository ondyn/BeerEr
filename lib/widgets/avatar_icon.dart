import 'package:beerer/theme/beer_theme.dart';
import 'package:flutter/material.dart';

/// A curated list of Material icon code‑points that users can pick as
/// their avatar.  Each entry is an [IconData] with
/// `fontFamily: 'MaterialIcons'`.
const List<IconData> kAvatarIcons = [
  // Drinks
  Icons.sports_bar, // 🍺
  Icons.local_bar, // 🍸
  Icons.wine_bar, // 🍷
  Icons.local_drink, // 🥤
  Icons.emoji_food_beverage, // ☕
  Icons.liquor, // 🥃
  // Party & music
  Icons.nightlife, // 🎉
  Icons.celebration, // 🎊
  Icons.music_note, // 🎵
  Icons.headphones, // 🎧
  Icons.piano, // 🎹
  Icons.audiotrack, // 🎶
  // Faces & people
  Icons.emoji_emotions, // 😊
  Icons.face, // 🙂
  Icons.face_2, // 👤
  Icons.face_3, // 👤
  Icons.face_4, // 👤
  Icons.face_5, // 👤
  Icons.face_6, // 👤
  Icons.sentiment_very_satisfied, // 😄
  Icons.mood, // 🙂
  Icons.psychology, // 🧠
  Icons.elderly, // 👴
  Icons.child_care, // 👶
  // Animals
  Icons.pets, // 🐾
  Icons.cruelty_free, // 🐰
  Icons.flutter_dash, // Dash mascot
  Icons.pest_control, // 🐛
  // Nature & weather
  Icons.park, // 🌲
  Icons.sunny, // ☀️
  Icons.ac_unit, // ❄️
  Icons.forest, // 🌳
  Icons.local_florist, // 🌸
  Icons.terrain, // ⛰️
  Icons.water, // 💧
  // Symbols & shapes
  Icons.star, // ⭐
  Icons.favorite, // ❤️
  Icons.bolt, // ⚡
  Icons.whatshot, // 🔥
  Icons.diamond, // 💎
  Icons.shield, // 🛡️
  Icons.flare, // ✨
  Icons.auto_awesome, // ✨
  // Sports & activities
  Icons.directions_bike, // 🚲
  Icons.skateboarding, // 🛹
  Icons.surfing, // 🏄
  Icons.pool, // 🏊
  Icons.downhill_skiing, // ⛷️
  Icons.snowboarding, // 🏂
  Icons.hiking, // 🥾
  Icons.kayaking, // 🛶
  Icons.kitesurfing, // 🪁
  Icons.paragliding, // 🪂
  Icons.scuba_diving, // 🤿
  Icons.sports_soccer, // ⚽
  Icons.sports_basketball, // 🏀
  Icons.sports_tennis, // 🎾
  Icons.sports_esports, // 🎮
  Icons.sports_hockey, // 🏒
  Icons.sports_martial_arts, // 🥋
  Icons.fitness_center, // 💪
  Icons.self_improvement, // 🧘
  // Travel & vehicles
  Icons.rocket_launch, // 🚀
  Icons.anchor, // ⚓
  Icons.sailing, // ⛵
  Icons.flight, // ✈️
  Icons.two_wheeler, // 🏍️
  Icons.directions_car, // 🚗
  // Science, art & tech
  Icons.science, // 🔬
  Icons.palette, // 🎨
  Icons.camera_alt, // 📷
  Icons.code, // </>
  Icons.terminal, // >_
  Icons.build, // 🔧
  Icons.engineering, // 👷
  // Food
  Icons.local_pizza, // 🍕
  Icons.icecream, // 🍦
  Icons.cake, // 🎂
  Icons.restaurant, // 🍽️
  // Misc personality
  Icons.military_tech, // 🎖️
  Icons.emoji_objects, // 💡
  Icons.theater_comedy, // 🎭
  Icons.catching_pokemon, // ⚾
  Icons.visibility, // 👁️
  Icons.fingerprint, // 🔏
];

/// Resolves a stored [codePoint] back to an [IconData] from the known
/// [kAvatarIcons] list.  Returns `null` when [codePoint] is `null` or not
/// found in the predefined set.
///
/// Using a lookup into constant [IconData] instances (rather than
/// `IconData(codePoint, …)`) keeps all references compile-time constant,
/// which lets `flutter build` tree-shake unused icon fonts.
IconData? iconFromCodePoint(int? codePoint) {
  if (codePoint == null) return null;
  for (final icon in kAvatarIcons) {
    if (icon.codePoint == codePoint) return icon;
  }
  return null;
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
