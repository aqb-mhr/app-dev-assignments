import 'package:flutter/material.dart';

import '../models/lost_item.dart';
import '../theme/app_theme.dart';

/// Pill-shaped Lost / Found / Claimed badge. Animates (fade + scale) when the
/// status changes, which makes live updates from Firestore easy to notice.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.large = false});

  final ItemStatus status;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(status, Theme.of(context).brightness);
    final textStyle = (large
            ? Theme.of(context).textTheme.labelLarge
            : Theme.of(context).textTheme.labelMedium)
        ?.copyWith(
      color: style.foreground,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Container(
        key: ValueKey(status),
        padding: EdgeInsets.symmetric(
          horizontal: large ? 14 : 10,
          vertical: large ? 7 : 4,
        ),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: large ? 18 : 14, color: style.foreground),
            SizedBox(width: large ? 6 : 4),
            Text(status.label, style: textStyle),
          ],
        ),
      ),
    );
  }
}

/// Rounded square with the item's category icon, tinted by status.
class ItemIcon extends StatelessWidget {
  const ItemIcon({
    super.key,
    required this.item,
    this.size = 52,
  });

  final LostItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(item.status, Theme.of(context).brightness);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        iconForItem(category: item.category, title: item.title),
        size: size * 0.5,
        color: style.foreground,
      ),
    );
  }
}
