import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/room.dart';
import 'core_providers.dart';

/// All rooms (seeded once in the console), ordered by name.
final roomsProvider = StreamProvider<List<Room>>(
    (ref) => ref.watch(roomRepositoryProvider).watchRooms());

/// Day shown in the room grid and the admin grid (shared).
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(ref.watch(clockProvider)());

  void select(DateTime day) => state = dateOnly(day);
}

final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

/// Family key: records have value equality, so (roomId, date) pairs are
/// cached / shared correctly.
typedef RoomDay = ({String roomId, String date});

/// Live ACTIVE bookings for one room on one date, via Firestore
/// `.snapshots()`. autoDispose closes the listener when you switch dates.
final roomBookingsProvider =
    StreamProvider.autoDispose.family<List<Booking>, RoomDay>((ref, key) {
  return ref
      .watch(bookingRepositoryProvider)
      .watchRoomBookings(roomId: key.roomId, date: key.date);
});
