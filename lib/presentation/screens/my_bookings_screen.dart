import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/booking_providers.dart';
import '../providers/core_providers.dart';
import '../widgets/booking_tile.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowTickerProvider).value ?? ref.read(clockProvider)();
    final user = ref.watch(currentUserProvider).value;
    final upcoming = ref.watch(mySortedBookingsProvider);
    final past = ref.watch(pastBookingsProvider);
    final theme = Theme.of(context);

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(text, style: theme.textTheme.titleSmall),
        );

    return RefreshIndicator(
      // Upcoming is already live; pull-to-refresh only reloads past pages.
      onRefresh: () => ref.refresh(pastBookingsProvider.future),
      child: ListView(
        children: [
          header('Upcoming (next 7 days)'),
          ...upcoming.when(
            loading: () => [const LinearProgressIndicator()],
            error: (e, _) => [ListTile(title: SelectableText('Error: $e'))],
            data: (list) => list.isEmpty
                ? [const ListTile(title: Text('No bookings yet.'))]
                : [
                    for (final b in list)
                      BookingTile(
                        booking: b,
                        now: now,
                        onCancel: user != null &&
                                b.isLiveActive(now) &&
                                now.isBefore(b.slotStart)
                            ? () => ref
                                .read(bookingControllerProvider.notifier)
                                .cancel(booking: b, user: user)
                            : null,
                      ),
                  ],
          ),
          const Divider(height: 32),
          header('Past bookings'),
          ...past.when(
            loading: () => [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            ],
            error: (e, _) => [ListTile(title: SelectableText('Error: $e'))],
            data: (state) => [
              if (state.items.isEmpty)
                const ListTile(title: Text('No past bookings.')),
              for (final b in state.items) BookingTile(booking: b, now: now),
              if (state.hasMore)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: state.isLoadingMore
                        ? const CircularProgressIndicator()
                        : OutlinedButton(
                            onPressed: () => ref
                                .read(pastBookingsProvider.notifier)
                                .loadMore(),
                            child: const Text('Load more'),
                          ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
