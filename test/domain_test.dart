import 'package:flutter_test/flutter_test.dart';
import 'package:roombook/core/date_utils.dart';
import 'package:roombook/core/email_validator.dart';
import 'package:roombook/core/slot_config.dart';
import 'package:roombook/domain/entities/booking.dart';

void main() {
  group('SlotConfig', () {
    test('09:00-21:00 in 30-minute slots = 24 slots', () {
      final starts = SlotConfig.slotStartsFor(DateTime(2026, 11, 19));
      expect(starts.length, 24);
      expect(hhmm(starts.first), '09:00');
      expect(hhmm(SlotConfig.slotEndFor(starts.last)), '21:00');
    });

    test('isValidSlotStart rejects off-grid and out-of-hours times', () {
      expect(SlotConfig.isValidSlotStart(DateTime(2026, 11, 19, 9, 30)), isTrue);
      expect(SlotConfig.isValidSlotStart(DateTime(2026, 11, 19, 9, 15)), isFalse);
      expect(SlotConfig.isValidSlotStart(DateTime(2026, 11, 19, 8, 30)), isFalse);
      expect(SlotConfig.isValidSlotStart(DateTime(2026, 11, 19, 21, 0)), isFalse);
    });
  });

  test('bookable window is today + next 6 days', () {
    final days = bookableDates(DateTime(2026, 11, 29, 15));
    expect(days.length, 7);
    expect(dateKey(days.first), '2026-11-29');
    expect(dateKey(days.last), '2026-12-05'); // crosses a month boundary
  });

  test('active booking whose slotEnd passed is shown as expired (no-show)', () {
    final b = Booking(
      id: 'x',
      roomId: 'r',
      roomName: 'R',
      date: '2026-11-19',
      slotStart: DateTime(2026, 11, 19, 9),
      slotEnd: DateTime(2026, 11, 19, 9, 30),
      userId: 'u',
      userName: 'U',
      status: BookingStatus.active,
    );
    expect(b.effectiveStatus(DateTime(2026, 11, 19, 9, 10)),
        BookingStatus.active);
    expect(b.effectiveStatus(DateTime(2026, 11, 19, 9, 30)),
        BookingStatus.expired);
    expect(b.copyWith(status: BookingStatus.cancelled)
            .effectiveStatus(DateTime(2026, 11, 19, 10)),
        BookingStatus.cancelled);
  });

  test('email domain validation', () {
    expect(EmailDomainValidator.isAllowed('a.b.12345@khi.iba.edu.pk'), isTrue);
    expect(EmailDomainValidator.isAllowed('someone@iba.edu.pk'), isTrue);
    expect(EmailDomainValidator.isAllowed('x@gmail.com'), isFalse);
    expect(EmailDomainValidator.isAllowed('x@iba.edu.pk.evil.com'), isFalse);
    expect(EmailDomainValidator.isAllowed('x@fakeiba.edu.pk'), isFalse);
  });
}
