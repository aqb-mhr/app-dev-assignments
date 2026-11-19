import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roombook/core/slot_config.dart';
import 'package:roombook/domain/entities/app_user.dart';
import 'package:roombook/domain/entities/booking.dart';
import 'package:roombook/domain/entities/room.dart';
import 'package:roombook/domain/failures.dart';
import 'package:roombook/presentation/providers/booking_providers.dart';
import 'package:roombook/presentation/providers/core_providers.dart';

import 'fakes/fake_booking_repository.dart';

/// Notifier-level tests: BookingController + fake repository.
/// No widgets, no Firebase.
void main() {
  // Frozen clock: Wed 19 Nov 2026, 10:05.
  final now = DateTime(2026, 11, 19, 10, 5);
  final today = DateTime(2026, 11, 19);
  DateTime slot(int index, {int dayOffset = 0}) => SlotConfig.slotStart(
      DateTime(today.year, today.month, today.day + dayOffset), index);

  const room = Room(id: 'r1', name: 'Room-0000-1', floor: 1, capacity: 2);
  const room2 = Room(id: 'r2', name: 'Room-0000-2', floor: 2, capacity: 2);
  const ali = AppUser(
      uid: 'ali', name: 'Ali', email: 'ali@khi.iba.edu.pk', role: UserRole.student);
  const sara = AppUser(
      uid: 'sara', name: 'Sara', email: 'sara@khi.iba.edu.pk', role: UserRole.student);
  const admin = AppUser(
      uid: 'adm', name: 'Admin', email: 'adm@khi.iba.edu.pk', role: UserRole.admin);

  late FakeBookingRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeBookingRepository();
    container = ProviderContainer(overrides: [
      bookingRepositoryProvider.overrideWithValue(repo),
      clockProvider.overrideWithValue(() => now),
    ]);
    // Keep the notifier alive for the whole test.
    container.listen(bookingControllerProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  BookingController controller() =>
      container.read(bookingControllerProvider.notifier);
  AsyncValue<String?> state() => container.read(bookingControllerProvider);

  test('booking a free slot succeeds and emits a success message', () async {
    await controller().book(room: room, slotStart: slot(4), user: ali);

    expect(state(), isA<AsyncData<String?>>());
    expect(state().value, contains('Room-0000-1'));
    expect(repo.bookings.values.single.userId, 'ali');
  });

  test('slot taken between screen load and tap -> SlotAlreadyTakenFailure',
      () async {
    // Sara's booking lands just before Ali's "transaction" runs.
    repo.competitorBeforeNextBook =
        (room: room, slotStart: slot(4), user: sara);

    await controller().book(room: room, slotStart: slot(4), user: ali);

    expect(state().hasError, isTrue);
    expect(state().error, isA<SlotAlreadyTakenFailure>());
    expect(state().error.toString(),
        'Someone just booked this — pick another slot');
    // Only Sara's booking exists.
    expect(repo.bookings.values.where((b) => b.slotStart == slot(4)).length, 1);
    expect(repo.bookings.values.single.userId, 'sara');
  });

  test('3rd active booking (on any date) is rejected by the 2-booking cap',
      () async {
    await controller().book(room: room, slotStart: slot(6), user: ali);
    await controller()
        .book(room: room2, slotStart: slot(2, dayOffset: 3), user: ali);
    expect(state().hasError, isFalse);

    await controller()
        .book(room: room, slotStart: slot(10, dayOffset: 5), user: ali);

    expect(state().error, isA<BookingLimitFailure>());
    expect(repo.bookings.length, 2);
  });

  test('cancelled and expired bookings do not count towards the cap',
      () async {
    // Expired: slot 0 (09:00-09:30) has ended at 10:05 but is still 'active'.
    repo.seed(room: room, slotStart: slot(0), user: ali);
    final b = repo.seed(room: room, slotStart: slot(8), user: ali);
    await controller().cancel(booking: b, user: ali);
    expect(repo.bookings[b.id]!.status, BookingStatus.cancelled);

    await controller().book(room: room, slotStart: slot(9), user: ali);
    await controller().book(room: room, slotStart: slot(10), user: ali);

    expect(state().hasError, isFalse);
    expect(
        repo.bookings.values.where((x) => x.isLiveActive(now)).length, 2);
  });

  test('two near-simultaneous bookings of the same slot: exactly one wins',
      () async {
    repo.latency = const Duration(milliseconds: 5);
    final results = await Future.wait([
      repo
          .createBooking(room: room, slotStart: slot(5), user: ali, now: now)
          .then<Object>((b) => b, onError: (Object e) => e),
      repo
          .createBooking(room: room, slotStart: slot(5), user: sara, now: now)
          .then<Object>((b) => b, onError: (Object e) => e),
    ]);

    expect(results.whereType<Booking>().length, 1);
    expect(results.whereType<SlotAlreadyTakenFailure>().length, 1);
  });

  test('student cannot force-cancel someone else\'s booking; admin can',
      () async {
    final saras = repo.seed(room: room, slotStart: slot(12), user: sara);

    await controller().forceCancel(booking: saras, admin: ali);
    expect(state().error, isA<NotAuthorizedFailure>());
    expect(repo.bookings[saras.id]!.status, BookingStatus.active);

    // Same function, using the owner path with another user's booking id.
    await controller().cancel(booking: saras, user: ali);
    expect(state().error, isA<NotAuthorizedFailure>());

    await controller().forceCancel(booking: saras, admin: admin);
    expect(state().hasError, isFalse);
    expect(repo.bookings[saras.id]!.status, BookingStatus.cancelled);
  });

  test('owner cannot cancel once the slot has started', () async {
    // slot 2 = 10:00-10:30, now = 10:05
    final started = repo.seed(room: room, slotStart: slot(2), user: ali);

    await controller().cancel(booking: started, user: ali);

    expect(state().error, isA<CannotCancelFailure>());
    expect(repo.bookings[started.id]!.status, BookingStatus.active);
  });

  test('cannot book a slot that already ended or is outside the 7-day window',
      () async {
    await controller().book(room: room, slotStart: slot(0), user: ali);
    expect(state().error, isA<InvalidSlotFailure>());

    await controller()
        .book(room: room, slotStart: slot(4, dayOffset: 7), user: ali);
    expect(state().error, isA<InvalidSlotFailure>());
    expect(repo.bookings, isEmpty);
  });
}
