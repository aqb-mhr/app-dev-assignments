enum BookingStatus {
  active,
  cancelled,
  expired,
  completed;

  static BookingStatus fromString(String? value) => BookingStatus.values
      .firstWhere((s) => s.name == value, orElse: () => BookingStatus.active);
}

class Booking {
  const Booking({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.date,
    required this.slotStart,
    required this.slotEnd,
    required this.userId,
    required this.userName,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String roomId;
  final String roomName;

  /// `yyyy-MM-dd` - used for the (roomId, date, status) grid query.
  final String date;
  final DateTime slotStart;
  final DateTime slotEnd;
  final String userId;
  final String userName;

  /// Status as stored in Firestore.
  final BookingStatus status;
  final DateTime? createdAt;

  /// No-show handling (client side): an `active` booking whose slotEnd has
  /// passed is shown as `expired`. A production system would flip the stored
  /// status with a scheduled Cloud Function instead.
  BookingStatus effectiveStatus(DateTime now) =>
      status == BookingStatus.active && !slotEnd.isAfter(now)
          ? BookingStatus.expired
          : status;

  /// Holds the slot right now and counts towards the 2-booking cap.
  bool isLiveActive(DateTime now) =>
      effectiveStatus(now) == BookingStatus.active;

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        roomId: roomId,
        roomName: roomName,
        date: date,
        slotStart: slotStart,
        slotEnd: slotEnd,
        userId: userId,
        userName: userName,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
