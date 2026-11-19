import 'package:material_ui/material_ui.dart';

import '../../core/date_utils.dart';
import '../../core/slot_config.dart';
import '../../domain/entities/booking.dart';

class SlotColors {
  SlotColors._();
  static const free = Color(0xFF43A047); // green
  static const taken = Color(0xFFE53935); // red - someone else
  static const mine = Color(0xFF1E88E5); // blue - me
  static const past = Color(0xFFBDBDBD); // grey - already over
}

enum SlotState { free, taken, mine, past }

/// Pure helper: what colour is a given slot?
SlotState slotStateFor({
  required DateTime slotStart,
  required Booking? booking,
  required String? myUid,
  required DateTime now,
}) {
  if (booking != null && booking.isLiveActive(now)) {
    return booking.userId == myUid ? SlotState.mine : SlotState.taken;
  }
  if (!SlotConfig.slotEndFor(slotStart).isAfter(now)) return SlotState.past;
  return SlotState.free;
}

/// A strip of [SlotConfig.slotsPerDay] small cells for one room/day.
class SlotStrip extends StatelessWidget {
  const SlotStrip({
    super.key,
    required this.day,
    required this.bookings,
    required this.myUid,
    required this.now,
    required this.onSlotTap,
  });

  final DateTime day;
  final List<Booking> bookings;
  final String? myUid;
  final DateTime now;
  final void Function(DateTime slotStart, Booking? booking, SlotState state)
      onSlotTap;

  @override
  Widget build(BuildContext context) {
    final byStart = {
      for (final b in bookings) b.slotStart.millisecondsSinceEpoch: b,
    };
    final starts = SlotConfig.slotStartsFor(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final start in starts)
              Expanded(
                child: Builder(builder: (context) {
                  final booking = byStart[start.millisecondsSinceEpoch];
                  final state = slotStateFor(
                    slotStart: start,
                    booking: booking,
                    myUid: myUid,
                    now: now,
                  );
                  return Tooltip(
                    message: '${hhmm(start)}–'
                        '${hhmm(SlotConfig.slotEndFor(start))}',
                    child: InkWell(
                      onTap: () => onSlotTap(start, booking, state),
                      child: Container(
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 0.75),
                        decoration: BoxDecoration(
                          color: _color(state),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
        const SizedBox(height: 4),
        // Hour labels under the strip.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var h = SlotConfig.openHour;
                h <= SlotConfig.closeHour;
                h += 3)
              Text('$h:00', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }

  static Color _color(SlotState s) => switch (s) {
        SlotState.free => SlotColors.free,
        SlotState.taken => SlotColors.taken,
        SlotState.mine => SlotColors.mine,
        SlotState.past => SlotColors.past,
      };
}

class SlotLegend extends StatelessWidget {
  const SlotLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 14,
        runSpacing: 4,
        children: [
          item(SlotColors.free, 'Free'),
          item(SlotColors.taken, 'Booked'),
          item(SlotColors.mine, 'Mine'),
          item(SlotColors.past, 'Past'),
        ],
      ),
    );
  }
}
