import 'dart:async';

import 'package:roombook/core/date_utils.dart';
import 'package:roombook/core/slot_config.dart';
import 'package:roombook/domain/booking_policy.dart';
import 'package:roombook/domain/entities/app_user.dart';
import 'package:roombook/domain/entities/booking.dart';
import 'package:roombook/domain/entities/room.dart';
import 'package:roombook/domain/failures.dart';
import 'package:roombook/domain/repositories/booking_repository.dart';

/// In-memory BookingRepository. No Firestore, no widgets.
///
/// It runs the SAME [BookingPolicy] the Firestore transaction runs, and the
/// check + write happen with no `await` in between, so (like a transaction)
/// it is atomic with respect to other calls on the Dart event loop.
class FakeBookingRepository implements BookingRepository {
  final Map<String, Booking> bookings = {};
  final Map<String, String> _locks = {}; // lockId -> bookingId
  int _seq = 0;

  /// Simulates the race: another student's booking lands for this
  /// (room, slotStart) after the UI loaded but before our "transaction".
  ({Room room, DateTime slotStart, AppUser user})? competitorBeforeNextBook;

  /// Artificial latency before the atomic section, so tests can fire two
  /// calls "at the same time".
  Duration latency = Duration.zero;

  String _lockId(String roomId, DateTime s) =>
      '${roomId}_${s.millisecondsSinceEpoch}';

  /// Directly insert a booking (test setup).
  Booking seed({
    required Room room,
    required DateTime slotStart,
    required AppUser user,
    BookingStatus status = BookingStatus.active,
  }) {
    final b = Booking(
      id: 'b${_seq++}',
      roomId: room.id,
      roomName: room.name,
      date: dateKey(slotStart),
      slotStart: slotStart,
      slotEnd: SlotConfig.slotEndFor(slotStart),
      userId: user.uid,
      userName: user.name,
      status: status,
    );
    bookings[b.id] = b;
    if (status == BookingStatus.active) {
      _locks[_lockId(room.id, slotStart)] = b.id;
    }
    return b;
  }

  @override
  Future<Booking> createBooking({
    required Room room,
    required DateTime slotStart,
    required AppUser user,
    required DateTime now,
  }) async {
    BookingPolicy.validateSlot(slotStart, now);
    if (latency > Duration.zero) await Future<void>.delayed(latency);

    final c = competitorBeforeNextBook;
    if (c != null) {
      competitorBeforeNextBook = null;
      seed(room: c.room, slotStart: c.slotStart, user: c.user);
    }

    // ---- atomic section (no awaits) ----
    final lockId = _lockId(room.id, slotStart);
    final holderId = _locks[lockId];
    BookingPolicy.ensureCanBook(
      bookingHoldingSlot: holderId == null ? null : bookings[holderId],
      usersBookings: bookings.values.where((b) => b.userId == user.uid),
      now: now,
    );
    return seed(room: room, slotStart: slotStart, user: user);
  }

  @override
  Future<void> cancelBooking({
    required String bookingId,
    required AppUser actor,
    required DateTime now,
    required bool force,
  }) async {
    final b = bookings[bookingId];
    if (b == null) throw const UnexpectedBookingFailure('Booking not found.');
    BookingPolicy.ensureCanCancel(
        booking: b, actor: actor, now: now, force: force);
    bookings[bookingId] = b.copyWith(status: BookingStatus.cancelled);
  }

  @override
  Stream<List<Booking>> watchRoomBookings(
          {required String roomId, required String date}) =>
      Stream.value(bookings.values
          .where((b) =>
              b.roomId == roomId &&
              b.date == date &&
              b.status == BookingStatus.active)
          .toList());

  @override
  Stream<List<Booking>> watchUpcomingForUser(
          {required String userId, required DateTime from}) =>
      Stream.value(bookings.values
          .where((b) => b.userId == userId && !b.slotEnd.isBefore(from))
          .toList());

  @override
  Future<PastBookingsPage> fetchPastBookings({
    required String userId,
    required DateTime before,
    required int pageSize,
    Object? cursor,
  }) async {
    final all = bookings.values
        .where((b) =>
            b.userId == userId &&
            b.status != BookingStatus.cancelled &&
            b.slotEnd.isBefore(before))
        .toList()
      ..sort((a, b) => b.slotEnd.compareTo(a.slotEnd));
    final start = (cursor as int?) ?? 0;
    final page = all.skip(start).take(pageSize).toList();
    return PastBookingsPage(
      items: page,
      cursor: start + page.length,
      hasMore: page.length == pageSize,
    );
  }
}
