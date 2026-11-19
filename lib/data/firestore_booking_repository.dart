import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/date_utils.dart';
import '../core/slot_config.dart';
import '../domain/booking_policy.dart';
import '../domain/entities/app_user.dart';
import '../domain/entities/booking.dart';
import '../domain/entities/room.dart';
import '../domain/failures.dart';
import '../domain/repositories/booking_repository.dart';

/// Id of the slot-lock document that represents the uniqueness key
/// (roomId, date, slotStart). The epoch-millis of slotStart already encodes
/// the date, so `roomId_millis` is unique per room per slot.
/// The same formula is re-checked in the security rules.
String slotLockId(String roomId, DateTime slotStart) =>
    '${roomId}_${slotStart.millisecondsSinceEpoch}';

class FirestoreBookingRepository implements BookingRepository {
  FirestoreBookingRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _locks =>
      _db.collection('slotLocks');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ---------------------------------------------------------------- reads

  @override
  Stream<List<Booking>> watchRoomBookings({
    required String roomId,
    required String date,
  }) {
    // Composite index: roomId ASC, date ASC, status ASC
    return _bookings
        .where('roomId', isEqualTo: roomId)
        .where('date', isEqualTo: date)
        .where('status', isEqualTo: BookingStatus.active.name)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Stream<List<Booking>> watchUpcomingForUser({
    required String userId,
    required DateTime from,
  }) {
    // Composite index: userId ASC, slotEnd ASC
    return _bookings
        .where('userId', isEqualTo: userId)
        .where('slotEnd', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('slotEnd')
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<PastBookingsPage> fetchPastBookings({
    required String userId,
    required DateTime before,
    required int pageSize,
    Object? cursor,
  }) async {
    // Composite index: status ASC, userId ASC, slotEnd DESC
    // (Firestore requires the whereIn field first for this query.)
    // Stored status of a no-show is still 'active' (client-side expiry),
    // so past = slot ended + not cancelled.
    Query<Map<String, dynamic>> q = _bookings
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
          BookingStatus.active.name,
          BookingStatus.completed.name,
          BookingStatus.expired.name,
        ])
        .where('slotEnd', isLessThan: Timestamp.fromDate(before))
        .orderBy('slotEnd', descending: true)
        .limit(pageSize);
    if (cursor is DocumentSnapshot) {
      q = q.startAfterDocument(cursor);
    }
    final snap = await q.get();
    return PastBookingsPage(
      items: snap.docs.map(_fromDoc).toList(),
      cursor: snap.docs.isEmpty ? cursor : snap.docs.last,
      hasMore: snap.docs.length == pageSize,
    );
  }

  // ------------------------------------------------------- atomic booking

  @override
  Future<Booking> createBooking({
    required Room room,
    required DateTime slotStart,
    required AppUser user,
    required DateTime now,
  }) async {
    BookingPolicy.validateSlot(slotStart, now);

    final slotEnd = SlotConfig.slotEndFor(slotStart);
    final lockId = slotLockId(room.id, slotStart);
    final lockRef = _locks.doc(lockId);
    final userRef = _users.doc(user.uid);
    final newRef = _bookings.doc(); // auto id, generated locally

    final booking = Booking(
      id: newRef.id,
      roomId: room.id,
      roomName: room.name,
      date: dateKey(slotStart),
      slotStart: slotStart,
      slotEnd: slotEnd,
      userId: user.uid,
      userName: user.name,
      status: BookingStatus.active,
    );

    // Business-rule failures are returned out of the transaction rather
    // than thrown through it, so the original typed failure always reaches
    // the caller (and a rejected attempt commits no writes).
    BookingFailure? failure;

    try {
      await _db.runTransaction((tx) async {
        failure = null; // the callback can be re-run on contention

        // 1) Re-read the slot. The lock doc points at whichever booking
        //    last claimed (roomId, slotStart). The slot is free if there is
        //    no lock, or the booking it points to is no longer active.
        final lockSnap = await tx.get(lockRef);
        Booking? holder;
        final holderId = lockSnap.data()?['bookingId'] as String?;
        if (holderId != null) {
          final holderSnap = await tx.get(_bookings.doc(holderId));
          if (holderSnap.exists) holder = _fromDoc(holderSnap);
        }

        // 2) Read this student's possibly-active bookings (ids tracked on
        //    users/{uid}). Reading them inside the transaction means two
        //    parallel bookings by the same student conflict and one retries.
        final userSnap = await tx.get(userRef);
        final ids = List<String>.from(
            userSnap.data()?['activeBookingIds'] as List? ?? const []);
        final mine = <Booking>[];
        for (final id in ids) {
          final s = await tx.get(_bookings.doc(id));
          if (s.exists) mine.add(_fromDoc(s));
        }

        // 3) Decide.
        try {
          BookingPolicy.ensureCanBook(
            bookingHoldingSlot: holder,
            usersBookings: mine,
            now: now,
          );
        } on BookingFailure catch (f) {
          failure = f;
          return;
        }

        // 4) Write all three docs together. If the lock or user doc changed
        //    since we read it, Firestore retries this whole callback.
        final stillActive =
            mine.where((b) => b.isLiveActive(now)).map((b) => b.id);
        tx.set(newRef, _toMap(booking, lockId));
        tx.set(lockRef, {
          'bookingId': newRef.id,
          'roomId': room.id,
          'slotStart': Timestamp.fromDate(slotStart),
          'userId': user.uid,
        });
        tx.update(userRef, {
          'activeBookingIds': [...stillActive, newRef.id],
        });
      });
    } on FirebaseException catch (e) {
      throw _mapFirebase(e);
    }

    final f = failure;
    if (f != null) throw f;
    return booking;
  }

  @override
  Future<void> cancelBooking({
    required String bookingId,
    required AppUser actor,
    required DateTime now,
    required bool force,
  }) async {
    final ref = _bookings.doc(bookingId);
    BookingFailure? failure;
    try {
      await _db.runTransaction((tx) async {
        failure = null;
        final snap = await tx.get(ref);
        if (!snap.exists) {
          failure = const UnexpectedBookingFailure('Booking not found.');
          return;
        }
        final booking = _fromDoc(snap);
        try {
          BookingPolicy.ensureCanCancel(
            booking: booking,
            actor: actor,
            now: now,
            force: force,
          );
        } on BookingFailure catch (f) {
          failure = f;
          return;
        }
        tx.update(ref, {
          'status': BookingStatus.cancelled.name,
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledBy': actor.uid,
        });
        if (booking.userId == actor.uid) {
          tx.update(_users.doc(actor.uid), {
            'activeBookingIds': FieldValue.arrayRemove([bookingId]),
          });
        }
      });
    } on FirebaseException catch (e) {
      throw _mapFirebase(e);
    }
    final f = failure;
    if (f != null) throw f;
  }

  // -------------------------------------------------------------- mapping

  BookingFailure _mapFirebase(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const NotAuthorizedFailure(
            'The server rejected this action (permission denied).');
      case 'aborted':
      case 'failed-precondition':
        // Too much contention on the same slot - someone else won.
        return const SlotAlreadyTakenFailure();
      case 'unavailable':
        return const UnexpectedBookingFailure(
            'You appear to be offline. Booking needs a connection.');
      default:
        return UnexpectedBookingFailure(e.message ?? e.code);
    }
  }

  static Map<String, dynamic> _toMap(Booking b, String lockId) => {
        'roomId': b.roomId,
        'roomName': b.roomName,
        'date': b.date,
        'slotStart': Timestamp.fromDate(b.slotStart),
        'slotEnd': Timestamp.fromDate(b.slotEnd),
        'userId': b.userId,
        'userName': b.userName,
        'status': b.status.name,
        'createdAt': FieldValue.serverTimestamp(),
        'lockId': lockId,
      };

  static Booking _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    DateTime ts(Object? v) =>
        v is Timestamp ? v.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
    return Booking(
      id: doc.id,
      roomId: d['roomId'] as String? ?? '',
      roomName: d['roomName'] as String? ?? '',
      date: d['date'] as String? ?? '',
      slotStart: ts(d['slotStart']),
      slotEnd: ts(d['slotEnd']),
      userId: d['userId'] as String? ?? '',
      userName: d['userName'] as String? ?? '',
      status: BookingStatus.fromString(d['status'] as String?),
      // null while the serverTimestamp is still pending locally
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
