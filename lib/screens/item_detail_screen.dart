import 'package:flutter/material.dart';

import '../actions/item_actions.dart';
import '../data/item_repository.dart';
import '../models/lost_item.dart';
import '../theme/app_theme.dart';
import '../utils/time_ago.dart';
import '../widgets/empty_state.dart';
import '../widgets/item_card.dart';
import '../widgets/status_badge.dart';

/// Full view of one item. Listens to the item's own document, so a status
/// change (or deletion) made on another device or in the console shows up
/// here immediately.
class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({
    super.key,
    required this.repository,
    required this.itemId,
    this.initialItem,
  });

  final ItemRepository repository;
  final String itemId;

  /// Rendered straight away while the document stream connects.
  final LostItem? initialItem;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late final Stream<LostItem?> _itemStream =
      widget.repository.watchItem(widget.itemId);

  bool _claiming = false;

  Future<void> _claim(LostItem item) async {
    // Spinner only after the user confirms, not while the dialog is open.
    await confirmAndClaim(
      context,
      widget.repository,
      item,
      onConfirmed: () {
        if (mounted) setState(() => _claiming = true);
      },
    );
    if (mounted) setState(() => _claiming = false);
  }
  
  Future<void> _delete(LostItem item) async {
    final navigator = Navigator.of(context);
    await confirmAndDelete(
      context,
      widget.repository,
      item,
      beforeDelete: () => navigator.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LostItem?>(
      stream: _itemStream,
      initialData: widget.initialItem,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _MessageScaffold(
            child: EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Can\'t load this item',
              message: '${snapshot.error}',
            ),
          );
        }

        final item = snapshot.data;
        if (item == null) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _MessageScaffold(
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _MessageScaffold(
            child: EmptyState(
              icon: Icons.inventory_2_rounded,
              title: 'This item was removed',
              message: 'It was deleted, possibly from another device.',
              actionLabel: 'Back to list',
              onAction: () => Navigator.of(context).maybePop(),
            ),
          );
        }

        return _DetailView(
          item: item,
          claiming: _claiming,
          onClaim: () => _claim(item),
          onDelete: () => _delete(item),
        );
      },
    );
  }
}

class _MessageScaffold extends StatelessWidget {
  const _MessageScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: child);
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({
    required this.item,
    required this.claiming,
    required this.onClaim,
    required this.onDelete,
  });

  final LostItem item;
  final bool claiming;
  final VoidCallback onClaim;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: const ValueKey('delete-item'),
            tooltip: 'Delete post',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: onDelete,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Center(
                child: Hero(
                  tag: itemHeroTag(item.id),
                  child: ItemIcon(item: item, size: 96),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.title.isEmpty ? 'Untitled item' : item.title,
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Center(child: StatusBadge(status: item.status, large: true)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: item.isClaimed
                    ? _ClaimedBanner(
                        key: const ValueKey('claimed-banner'),
                        claimedAt: item.claimedAt,
                      )
                    : const SizedBox.shrink(key: ValueKey('no-banner')),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: iconForItem(category: item.category),
                        label: 'Category',
                        value: item.category,
                      ),
                      const _RowDivider(),
                      _InfoRow(
                        icon: Icons.place_rounded,
                        label: item.status == ItemStatus.lost
                            ? 'Last seen at'
                            : 'Location',
                        value: item.location,
                      ),
                      const _RowDivider(),
                      _InfoRow(
                        icon: Icons.person_rounded,
                        label: 'Posted by',
                        value: item.postedBy,
                      ),
                      const _RowDivider(),
                      _InfoRow(
                        icon: Icons.schedule_rounded,
                        label: 'Posted',
                        value: item.createdAt == null
                            ? 'Just now'
                            : '${formatDate(item.createdAt!, withTime: true)}'
                                '  (${timeAgo(item.createdAt)})',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_rounded,
                            size: 20,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text('Description', style: text.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        item.description.isEmpty
                            ? 'No description provided.'
                            : item.description,
                        style: text.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  key: const ValueKey('claim-button'),
                  onPressed: item.isClaimed || claiming ? null : onClaim,
                  icon: claiming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          item.isClaimed
                              ? Icons.verified_rounded
                              : Icons.handshake_rounded,
                        ),
                  label: Text(
                    item.isClaimed
                        ? 'Already claimed'
                        : claiming
                            ? 'Claiming…'
                            : 'Mark as Claimed',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClaimedBanner extends StatelessWidget {
  const _ClaimedBanner({super.key, required this.claimedAt});

  final DateTime? claimedAt;

  @override
  Widget build(BuildContext context) {
    final style =
        StatusStyle.of(ItemStatus.claimed, Theme.of(context).brightness);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.task_alt_rounded, color: style.foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Returned to its owner ${timeAgo(claimedAt)}',
                style: text.bodyMedium?.copyWith(
                  color: style.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(value.isEmpty ? 'Not given' : value, style: text.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 68,
      endIndent: 18,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}
