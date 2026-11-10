import 'package:flutter/material.dart';

import '../models/lost_item.dart';
import '../theme/app_theme.dart';

/// All / Lost / Found / Claimed chips with live counts.
class StatusFilterBar extends StatelessWidget {
  const StatusFilterBar({
    super.key,
    required this.selected,
    required this.counts,
    required this.total,
    required this.onChanged,
  });

  /// Null means "All".
  final ItemStatus? selected;
  final Map<ItemStatus, int> counts;
  final int total;
  final ValueChanged<ItemStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _chip(
            context,
            key: const ValueKey('filter-all'),
            label: 'All',
            count: total,
            isSelected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final status in ItemStatus.values) ...[
            const SizedBox(width: 8),
            _chip(
              context,
              key: ValueKey('filter-${status.name}'),
              label: status.label,
              count: counts[status] ?? 0,
              isSelected: selected == status,
              style: StatusStyle.of(status, brightness),
              onTap: () => onChanged(status),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required Key key,
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    StatusStyle? style,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selectedBg = style?.background ?? scheme.secondaryContainer;
    final selectedFg = style?.foreground ?? scheme.onSecondaryContainer;

    return ChoiceChip(
      key: key,
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      avatar: style == null
          ? null
          : Icon(
              style.icon,
              size: 16,
              color: isSelected ? selectedFg : scheme.onSurfaceVariant,
            ),
      label: Text('$label  $count'),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? selectedFg : scheme.onSurfaceVariant,
      ),
      selectedColor: selectedBg,
      backgroundColor: scheme.surface,
      side: BorderSide(
        color: isSelected ? Colors.transparent : scheme.outlineVariant,
      ),
      shape: const StadiumBorder(),
    );
  }
}
