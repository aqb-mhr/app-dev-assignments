import 'package:flutter/material.dart';

import '../data/item_repository.dart';
import '../logic/item_filter.dart';
import '../models/lost_item.dart';
import '../widgets/empty_state.dart';
import '../widgets/item_card.dart';
import '../widgets/status_filter_bar.dart';
import 'add_item_screen.dart';

/// Home screen: live list of items with title search and status filter.
class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key, required this.repository});

  final ItemRepository repository;

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  // Created once so rebuilds (typing in search) don't resubscribe.
  late final Stream<List<LostItem>> _itemsStream =
      widget.repository.watchItems();

  final _searchController = TextEditingController();
  String _query = '';
  ItemStatus? _statusFilter; // null = All
  bool _seeding = false;

  ItemRepository get _repo => widget.repository;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _seedSampleItems() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _seeding = true);
    try {
      final added = await _repo.seedSampleItems();
      messenger.showSnackBar(SnackBar(
        content: Text(
          added == 0
              ? 'Sample items are already in Firestore'
              : 'Added $added sample items',
        ),
      ));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not seed items: $error')),
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _openAddItem() async {
    final messenger = ScaffoldMessenger.of(context);
    final postedTitle = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AddItemScreen(repository: _repo),
      ),
    );
    if (postedTitle != null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Posted "$postedTitle"')),
      );
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _statusFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-item-fab'),
        onPressed: _openAddItem,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post item'),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: StreamBuilder<List<LostItem>>(
              stream: _itemsStream,
              builder: (context, snapshot) {
                final all = snapshot.data ?? const <LostItem>[];
                final visible =
                    filterItems(all, query: _query, status: _statusFilter);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      liveCount: all.length,
                      connected: snapshot.hasData,
                      seeding: _seeding,
                      onSeed: _seedSampleItems,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: TextField(
                        key: const ValueKey('search-field'),
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search by title',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                        ),
                      ),
                    ),
                    StatusFilterBar(
                      selected: _statusFilter,
                      counts: countByStatus(all),
                      total: all.length,
                      onChanged: (status) =>
                          setState(() => _statusFilter = status),
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: _buildBody(snapshot, all, visible)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    AsyncSnapshot<List<LostItem>> snapshot,
    List<LostItem> all,
    List<LostItem> visible,
  ) {
    if (snapshot.hasError) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Can\'t reach Firestore',
        message: '${snapshot.error}',
      );
    }
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (all.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_rounded,
        title: 'Nothing posted yet',
        message: 'Post the first lost or found item, or load the 8 sample '
            'items from the assignment.',
        actionLabel: 'Load sample items',
        onAction: _seedSampleItems,
        busy: _seeding,
      );
    }
    if (visible.isEmpty) {
      return EmptyState(
        icon: Icons.travel_explore_rounded,
        title: 'No matches',
        message: 'No items match your search and filter.',
        actionLabel: 'Clear filters',
        onAction: _clearFilters,
      );
    }

    return ListView.separated(
      key: const ValueKey('items-list'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = visible[index];
        return ItemCard(key: ValueKey(item.id), item: item);
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.liveCount,
    required this.connected,
    required this.seeding,
    required this.onSeed,
  });

  final int liveCount;
  final bool connected;
  final bool seeding;
  final VoidCallback onSeed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lost & Found', style: text.headlineSmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: connected
                            ? const Color(0xFF16A34A)
                            : scheme.outline,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      connected
                          ? 'IBA campus  ·  $liveCount items, live'
                          : 'Connecting…',
                      style: text.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert_rounded),
            enabled: !seeding,
            onSelected: (value) {
              if (value == 'seed') onSeed();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'seed',
                child: ListTile(
                  leading: Icon(Icons.auto_awesome_rounded),
                  title: Text('Load sample items'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
