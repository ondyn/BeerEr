import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/widgets/avatar_icon.dart';
import 'package:flutter/material.dart';

/// Shows a grid dialog letting the user pick a Material icon as their
/// avatar.  Returns the selected [IconData.codePoint] or `null` if
/// dismissed.  Passing [currentCodePoint] highlights the currently
/// selected icon.
Future<int?> showAvatarPicker(
  BuildContext context, {
  int? currentCodePoint,
}) {
  return showDialog<int?>(
    context: context,
    builder: (ctx) => _AvatarPickerDialog(currentCodePoint: currentCodePoint),
  );
}

class _AvatarPickerDialog extends StatelessWidget {
  const _AvatarPickerDialog({this.currentCodePoint});

  final int? currentCodePoint;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.chooseAvatar),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: kAvatarIcons.length + 1, // +1 for "none" option
          itemBuilder: (ctx, index) {
            // First item = remove avatar
            if (index == 0) {
              final isSelected = currentCodePoint == null;
              return _AvatarCell(
                icon: null,
                label: 'A',
                isSelected: isSelected,
                onTap: () => Navigator.pop(context, -1), // sentinel
              );
            }

            final icon = kAvatarIcons[index - 1];
            final isSelected = currentCodePoint == icon.codePoint;
            return _AvatarCell(
              icon: icon,
              isSelected: isSelected,
              onTap: () => Navigator.pop(context, icon.codePoint),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
      ],
    );
  }
}

class _AvatarCell extends StatelessWidget {
  const _AvatarCell({
    this.icon,
    this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData? icon;
  final String? label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: BeerColors.primaryAmber, width: 2.5)
              : null,
          color: isSelected
              ? BeerColors.primaryAmber.withValues(alpha: 0.15)
              : BeerColors.surfaceVariant,
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: BeerColors.onSurface, size: 26)
              : Text(
                  label ?? '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: BeerColors.onSurface,
                  ),
                ),
        ),
      ),
    );
  }
}
