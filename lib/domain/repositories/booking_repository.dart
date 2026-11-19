import '../entities/app_user.dart';
import '../entities/booking.dart';
import '../entities/room.dart';

/// One page of past bookings. [cursor] is opaque to the domain layer
/// (in the Firestore implementation it is the last DocumentSnapshot,
/// passed back into `startAfterDocument`).
class PastBookingsPage {
  const PastBookingsPage({
    required this.items,
    required this.cursor,
    required this.hasMore,
  });

  final List<Booking> items;
  final Object? cursor;
  final bool hasMore;
}

abstract interface class BookingRepository {
  /// Live ACTIVE bookings of one room on one date (`yyyy-MM-dd`).
  Stream<List<Booking>> watchRoomBookings({
    required String roomId,
    required String date,
  });

  /// Live bookings of [userId] whose slot ends on/after [from]
  /// (today + next 6 days), soonest first. Includes cancelled ones.
  Stream<List<Booking>> watchUpcomingForUser({
    required String userId,
    required DateTime from,
  });

  /// Past (completed / expired) bookings ending before [before],
  /// newest first, [pageSize] at a time.
  Future<PastBookingsPage> fetchPastBookings({
    required String userId,
    required DateTime before,
    required int pageSize,
    Object? cursor,
  });

  /// Atomically books (room, slotStart) for [user].
  /// Throws [SlotAlreadyTakenFailure] / [BookingLimitFailure].
  Future<Booking> createBooking({
    required Room room,
    required DateTime slotStart,
    required AppUser user,
    required DateTime now,
  });

  /// Sets status to 'cancelled' (never deletes).
  /// [force] = admin force-cancel of someone else's booking.
  Future<void> cancelBooking({
    required String bookingId,
    required AppUser actor,
    required DateTime now,
    required bool force,
  });
}
