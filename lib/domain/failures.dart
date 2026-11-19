/// Expected, user-facing booking errors. The UI shows [message] in a
/// SnackBar via `ref.listen`.
sealed class BookingFailure implements Exception {
  const BookingFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Another active booking already holds (roomId, date, slotStart).
class SlotAlreadyTakenFailure extends BookingFailure {
  const SlotAlreadyTakenFailure()
      : super('Someone just booked this — pick another slot');
}

/// Student already holds the maximum number of active bookings.
class BookingLimitFailure extends BookingFailure {
  const BookingLimitFailure(int max)
      : super('You already have $max active bookings. '
            'Cancel one or wait for it to finish first.');
}

/// Slot has already ended, or is outside the 7-day window / opening hours.
class InvalidSlotFailure extends BookingFailure {
  const InvalidSlotFailure(super.message);
}

/// The current user is not allowed to perform this action.
class NotAuthorizedFailure extends BookingFailure {
  const NotAuthorizedFailure(super.message);
}

/// Booking can no longer be cancelled (already started / not active).
class CannotCancelFailure extends BookingFailure {
  const CannotCancelFailure(super.message);
}

class UnexpectedBookingFailure extends BookingFailure {
  const UnexpectedBookingFailure(super.message);
}

/// Login / sign-up errors.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
