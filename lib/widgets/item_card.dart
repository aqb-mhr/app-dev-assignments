import 'package:flutter/material.dart';

import '../models/lost_item.dart';
import '../utils/time_ago.dart';
import 'status_badge.dart';

/// Hero tag shared by the list card icon and the detail screen header.
String itemHeroTag(String id) => 'item-icon-$id';

/// One row in the list: icon, title, where/when, status and category.
class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item, this.onTap});

  final LostItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
            children: [
              Hero(
                tag: itemHeroTag(item.id),
                child: ItemIcon(item: item),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? 'Untitled item' : item.title,
                      style: text.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.place_rounded,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            item.location.isEmpty ? 'Unknown' : item.location,
                            style: muted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('  ·  ${timeAgo(item.createdAt)}', style: muted),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusBadge(status: item.status),
                        const SizedBox(width: 8),
                        if (item.category.isNotEmpty)
                          Flexible(
                            child: Text(
                              item.category,
                              style: text.labelMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
