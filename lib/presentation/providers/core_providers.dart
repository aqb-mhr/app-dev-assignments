import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/firebase_auth_repository.dart';
import '../../data/firestore_booking_repository.dart';
import '../../data/firestore_room_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/room_repository.dart';

// ---- Infrastructure (overridden in tests) ----------------------------------

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

/// Injectable clock so tests can freeze "now".
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Re-emits "now" every 30 s so slot cells / bookings flip to
/// past / expired on screen without a manual refresh.
final nowTickerProvider = StreamProvider<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => clock());
});

// ---- Repositories (data layer behind domain interfaces) --------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) =>
    FirebaseAuthRepository(
        ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider)));

final roomRepositoryProvider = Provider<RoomRepository>(
    (ref) => FirestoreRoomRepository(ref.watch(firestoreProvider)));

final bookingRepositoryProvider = Provider<BookingRepository>(
    (ref) => FirestoreBookingRepository(ref.watch(firestoreProvider)));
