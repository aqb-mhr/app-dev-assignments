import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../core/date_utils.dart';
import '../../domain/entities/booking.dart';

class BookingTile extends StatelessWidget {
  const BookingTile({
    super.key,
    required this.booking,
    required this.now,
    this.onCancel,
  });

  final Booking booking;
  final DateTime now;

  /// Null hides the cancel button.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final status = booking.effectiveStatus(now);
    final (color, label) = switch (status) {
      BookingStatus.active => (Colors.blue, 'Active'),
      BookingStatus.cancelled => (Colors.grey, 'Cancelled'),
      BookingStatus.expired => (Colors.orange, 'Expired'),
      BookingStatus.completed => (Colors.green, 'Completed'),
    };
    return ListTile(
      title: Text(booking.roomName.isEmpty ? booking.roomId : booking.roomName),
      subtitle: Text('${DateFormat('EEE d MMM').format(booking.slotStart)} · '
          '${hhmm(booking.slotStart)}–${hhmm(booking.slotEnd)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(label),
            labelStyle: TextStyle(color: color.shade800, fontSize: 12),
            backgroundColor: color.shade50,
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
          ),
          if (onCancel != null)
            IconButton(
              tooltip: 'Cancel booking',
              icon: const Icon(Icons.close),
              onPressed: onCancel,
            ),
        ],
      ),
    );
  }
}
