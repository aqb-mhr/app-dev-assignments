import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/slot_config.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/room.dart';
import '../providers/auth_providers.dart';
import '../providers/booking_providers.dart';
import '../providers/core_providers.dart';
import '../providers/room_providers.dart';
import 'slot_strip.dart';

/// One room + its live slot strip for the selected date.
/// [adminMode] additionally lists every booking with a force-cancel button.
class RoomCard extends ConsumerWidget {
  const RoomCard({super.key, required this.room, this.adminMode = false});

  final Room room;
  final bool adminMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDateProvider);
    final now = ref.watch(nowTickerProvider).value ?? ref.read(clockProvider)();
    final user = ref.watch(currentUserProvider).value;
    final bookingsAsync =
        ref.watch(roomBookingsProvider((roomId: room.id, date: dateKey(day))));

    final bookings = bookingsAsync.value ?? const <Booking>[];
    final live = bookings.where((b) => b.isLiveActive(now)).toList()
      ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
    final freeCount = SlotConfig.slotStartsFor(day)
        .where((s) =>
            SlotConfig.slotEndFor(s).isAfter(now) &&
            !live.any((b) => b.slotStart == s))
        .length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(room.name,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Text('Floor ${room.floor} · ${room.capacity} seats',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 2),
            Text('$freeCount free slots',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            if (bookingsAsync.hasError)
              Text('Could not load bookings: ${bookingsAsync.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error))
            else if (bookingsAsync.isLoading && !bookingsAsync.hasValue)
              const LinearProgressIndicator()
            else
              SlotStrip(
                day: day,
                bookings: live,
                myUid: user?.uid,
                now: now,
                onSlotTap: (start, booking, state) =>
                    _onSlotTap(context, ref, start, booking, state),
              ),
            if (adminMode && live.isNotEmpty) ...[
              const Divider(height: 20),
              for (final b in live)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${hhmm(b.slotStart)}–${hhmm(b.slotEnd)}'
                      '  ${b.userName}'),
                  trailing: TextButton(
                    onPressed: () => _confirmForceCancel(context, ref, b),
                    child: const Text('Force cancel'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onSlotTap(BuildContext context, WidgetRef ref,
      DateTime start, Booking? booking, SlotState state) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final label = '${room.name}, ${hhmm(start)}–'
        '${hhmm(SlotConfig.slotEndFor(start))}';

    switch (state) {
      case SlotState.past:
        messenger.showSnackBar(
            const SnackBar(content: Text('That slot is already over.')));
      case SlotState.taken:
        if (adminMode && booking != null) {
          await _confirmForceCancel(context, ref, booking);
        } else {
          messenger.showSnackBar(
              SnackBar(content: Text('$label is already booked.')));
        }
      case SlotState.mine:
        if (booking == null) return;
        final ok = await _confirm(context, 'Cancel booking?',
            'Cancel your booking for $label?', 'Cancel booking');
        if (ok) {
          await ref
              .read(bookingControllerProvider.notifier)
              .cancel(booking: booking, user: user);
        }
      case SlotState.free:
        final ok = await _confirm(
            context, 'Book this slot?', label, 'Book');
        if (ok) {
          await ref
              .read(bookingControllerProvider.notifier)
              .book(room: room, slotStart: start, user: user);
        }
    }
  }

  Future<void> _confirmForceCancel(
      BuildContext context, WidgetRef ref, Booking b) async {
    final admin = ref.read(currentUserProvider).value;
    if (admin == null) return;
    final ok = await _confirm(
      context,
      'Force-cancel booking?',
      '${b.userName} · ${room.name} · ${hhmm(b.slotStart)}–${hhmm(b.slotEnd)}',
      'Force cancel',
    );
    if (ok) {
      await ref
          .read(bookingControllerProvider.notifier)
          .forceCancel(booking: b, admin: admin);
    }
  }

  static Future<bool> _confirm(BuildContext context, String title,
      String body, String action) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Back')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
        ],
      ),
    );
    return result ?? false;
  }
}
