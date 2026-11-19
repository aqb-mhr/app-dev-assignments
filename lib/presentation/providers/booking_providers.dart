import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/slot_config.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/booking_repository.dart';
import 'auth_providers.dart';
import 'core_providers.dart';

// ---------------------------------------------------------------- My bookings

/// Live stream of the signed-in student's bookings from today onwards
/// (covers the whole 7-day bookable window).
final myUpcomingBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) return Stream.value(const []);
  final today = dateOnly(ref.read(clockProvider)());
  return ref
      .watch(bookingRepositoryProvider)
      .watchUpcomingForUser(userId: uid, from: today);
});

/// Derived view: still-active bookings first (soonest first), then
/// expired / cancelled ones. Recomputes when the stream OR the clock ticks.
final mySortedBookingsProvider = Provider<AsyncValue<List<Booking>>>((ref) {
  final now = ref.watch(nowTickerProvider).value ?? ref.read(clockProvider)();
  return ref.watch(myUpcomingBookingsProvider).whenData((list) {
    final sorted = [...list]..sort((a, b) {
        final aLive = a.isLiveActive(now) ? 0 : 1;
        final bLive = b.isLiveActive(now) ? 0 : 1;
        if (aLive != bLive) return aLive - bLive;
        return a.slotStart.compareTo(b.slotStart);
      });
    return sorted;
  });
});

// --------------------------------------------------- Past bookings (paged)

class PastBookingsState {
  const PastBookingsState({
    this.items = const [],
    this.cursor,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<Booking> items;
  final Object? cursor;
  final bool hasMore;
  final bool isLoadingMore;

  PastBookingsState copyWith({
    List<Booking>? items,
    Object? cursor,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      PastBookingsState(
        items: items ?? this.items,
        cursor: cursor ?? this.cursor,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

/// First page on build, then [loadMore] fetches the next 10 with
/// `startAfterDocument(cursor)`.
class PastBookingsNotifier extends AsyncNotifier<PastBookingsState> {
  @override
  Future<PastBookingsState> build() async {
    final uid = ref.watch(authStateProvider).value;
    if (uid == null) return const PastBookingsState(hasMore: false);
    final page = await _fetch(uid, null);
    return PastBookingsState(
        items: page.items, cursor: page.cursor, hasMore: page.hasMore);
  }

  Future<void> loadMore() async {
    final current = state.value;
    final uid = ref.read(authStateProvider).value;
    if (current == null ||
        uid == null ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await _fetch(uid, current.cursor);
      if (!ref.mounted) return;
      state = AsyncData(current.copyWith(
        items: [...current.items, ...page.items],
        cursor: page.cursor,
        hasMore: page.hasMore,
        isLoadingMore: false,
      ));
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
    }
  }

  Future<PastBookingsPage> _fetch(String uid, Object? cursor) {
    final today = dateOnly(ref.read(clockProvider)());
    return ref.read(bookingRepositoryProvider).fetchPastBookings(
          userId: uid,
          before: today,
          pageSize: SlotConfig.pastPageSize,
          cursor: cursor,
        );
  }
}

final pastBookingsProvider =
    AsyncNotifierProvider<PastBookingsNotifier, PastBookingsState>(
        PastBookingsNotifier.new);

// ---------------------------------------------------- Booking actions

/// Book / cancel / force-cancel. State is the success message of the last
/// action (AsyncData), the typed BookingFailure (AsyncError), or
/// AsyncLoading while the transaction runs. No BuildContext in here - the
/// widget shows SnackBars through `ref.listen`.
class BookingController extends AsyncNotifier<String?> {
  @override
  String? build() => null;

  Future<void> book({
    required Room room,
    required DateTime slotStart,
    required AppUser user,
  }) =>
      _run(() async {
        await ref.read(bookingRepositoryProvider).createBooking(
              room: room,
              slotStart: slotStart,
              user: user,
              now: ref.read(clockProvider)(),
            );
        return 'Booked ${room.name} · ${hhmm(slotStart)}';
      });

  /// Owner cancels their own booking (only before it starts).
  Future<void> cancel({required Booking booking, required AppUser user}) =>
      _run(() async {
        await ref.read(bookingRepositoryProvider).cancelBooking(
              bookingId: booking.id,
              actor: user,
              now: ref.read(clockProvider)(),
              force: false,
            );
        return 'Booking cancelled';
      });

  /// Admin cancels anyone's booking. Also enforced by security rules.
  Future<void> forceCancel({
    required Booking booking,
    required AppUser admin,
  }) =>
      _run(() async {
        await ref.read(bookingRepositoryProvider).cancelBooking(
              bookingId: booking.id,
              actor: admin,
              now: ref.read(clockProvider)(),
              force: true,
            );
        return 'Cancelled ${booking.userName}\'s booking';
      });

  Future<void> _run(Future<String> Function() action) async {
    if (state.isLoading) return; // ignore double taps
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) state = result;
  }
}

final bookingControllerProvider =
    AsyncNotifierProvider<BookingController, String?>(BookingController.new);
