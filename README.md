# IBA RoomBook

Real-time study-room booking for the IBA library, built with Flutter, **Riverpod** and **Firebase** (Auth + Cloud Firestore).
CSE-450 Assignment 4. Branch: `feature/roombook`.

Students see live availability for 6 rooms × 24 half-hour slots (09:00–21:00) for today and the next 6 days. They can book a slot without colliding with anyone else, and they can hold at most 2 active bookings at a time. Admins see every booking and can force-cancel any of them.

---

## Running it

```bash
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure          # overwrites lib/firebase_options.dart with your project
flutter run
```

Firebase console setup:
1. **Authentication → Sign-in method:** enable *Email/Password*.
2. **Firestore → Rules:** paste [`rules.txt`](rules.txt).
3. **Firestore → Indexes:** create the 3 composite indexes in [`firestore.indexes.json`](firestore.indexes.json). You can also just click the link Firestore prints in the debug console the first time each query runs.
4. **Seed `rooms`** by hand with the values below.
5. Sign up a second account in the app. Then in the console set `users/{thatUid}.role = "admin"`.

Tests: `flutter test` · Lints: `flutter analyze`

---

## Personalized seed data

> **TODO (student):** fill in your roll number. Formula: N = last 4 digits of the roll number, left-padded with zeros. Capacity = (N mod 8) + 2. Odd rooms go on floor 1 and even rooms on floor 2.

Roll number: `_____` → **N = `NNNN`** → capacity = (`NNNN` mod 8) + 2 = **`C`**

| Doc id (any) | name        | floor | capacity |
|--------------|-------------|-------|----------|
| room1        | Room-NNNN-1 | 1     | C        |
| room2        | Room-NNNN-2 | 2     | C        |
| room3        | Room-NNNN-3 | 1     | C        |
| room4        | Room-NNNN-4 | 2     | C        |
| room5        | Room-NNNN-5 | 1     | C        |
| room6        | Room-NNNN-6 | 2     | C        |

`floor` and `capacity` must be stored as **numbers**.

---

## Data model (Cloud Firestore)

| Collection | Fields | Notes |
|---|---|---|
| `rooms/{id}` | `name`, `floor`, `capacity` | 6 rooms, seeded once |
| `bookings/{autoId}` | `roomId`, `roomName`, `date` (`yyyy-MM-dd`), `slotStart`, `slotEnd` (**Timestamps**), `userId`, `userName`, `status`, `createdAt`, `lockId`, (`cancelledAt`, `cancelledBy`) | `status`: `active` / `cancelled` / `expired` / `completed`. Never deleted. |
| `users/{uid}` | `uid`, `name`, `email`, `role`, `activeBookingIds`, `createdAt` | `role`: `student` / `admin` |
| `slotLocks/{roomId_slotStartMillis}` | `bookingId`, `roomId`, `slotStart`, `userId` | One doc per (room, slot). This is the uniqueness key. |

### Why the extra `slotLocks` collection?
The uniqueness key is (roomId, date, slotStart). Firestore client transactions can only `get()` **documents**. They cannot run a query and lock its results. So the key itself has to be a document id: `slotLocks/{roomId}_{slotStart epoch-millis}` (the millis value already includes the date). The lock points at the booking that last claimed the slot.

- The slot is **free** if there is no lock, or if the booking the lock points to is no longer active (cancelled or already over).
- Cancelling only flips the booking's `status`. The slot frees up immediately, and the old booking doc stays as the audit trail.
- A new booking gets a fresh auto-id document, so cancel → rebook never overwrites history.

---

## The booking transaction ([`firestore_booking_repository.dart`](lib/data/firestore_booking_repository.dart) → `createBooking`)

All of these steps run inside one `runTransaction`:

1. `tx.get(slotLock)`. If it points to a booking, `tx.get(thatBooking)`. This **re-reads the target slot**.
2. `tx.get(users/{me})` → `activeBookingIds`, then `tx.get` each of those bookings. These are **my active bookings, counted across all dates**.
3. `BookingPolicy.ensureCanBook(...)` (a pure domain function) checks two things:
   - Is the slot held by a booking that is still active? If so → `SlotAlreadyTakenFailure` ("Someone just booked this — pick another slot").
   - Do I already have 2 or more live-active bookings? If so → `BookingLimitFailure`.
4. Only then are the three writes made together: the new booking, the lock (now pointing to it), and my `activeBookingIds` (with stale ids pruned).

If another device changes the lock or my user doc between our reads and our commit, Firestore **retries the whole callback**. On the retry it sees the other booking and fails cleanly. A plain read-then-write has no such guarantee: two devices can both read "free" and then both write.

Business failures are passed *out* of the transaction as a value and thrown after it returns. This means a rejected attempt commits nothing, and the UI always receives the typed failure.

The security rules **independently** enforce the same guarantee. A lock can only be overwritten if the booking it currently points to is no longer active, and a booking can only be created together with its matching lock.

### Changing the slot length (e.g. 30 → 20 min)
Edit only `slotLength` in [`lib/core/slot_config.dart`](lib/core/slot_config.dart). Everything else is derived from it: `slotsPerDay` (24 → 36), the slot start/end times, the strip width, `isValidSlotStart`, and the lock ids (they use the slot start time). Existing bookings with 30-min boundaries would no longer line up with the new 20-min grid, so you would need to clear test data or migrate it.

---

## Architecture

```
lib/
  core/            slot_config, date utils, email domain validator (pure Dart)
  domain/          entities, failures, BookingPolicy (rules), repository interfaces
  data/            Firebase/Firestore implementations of those interfaces
  presentation/
    providers/     Riverpod providers + notifiers (no BuildContext anywhere)
    screens/       auth gate, login, home shell, rooms grid, my bookings
    widgets/       date selector, slot strip, room card, booking tile
```

| Provider | Type | Purpose |
|---|---|---|
| `authStateProvider` | `StreamProvider<String?>` | Persisted Firebase session |
| `currentUserProvider` | `StreamProvider<AppUser?>` | Live `users/{uid}` (role) |
| `roomsProvider` | `StreamProvider` | Rooms |
| `selectedDateProvider` | `NotifierProvider` | Day picked in the date selector |
| `roomBookingsProvider` | `StreamProvider.autoDispose.family<…, (roomId, date)>` | Live `.snapshots()` per room/day |
| `myUpcomingBookingsProvider` → `mySortedBookingsProvider` | `StreamProvider` → derived `Provider` | My bookings, upcoming first |
| `pastBookingsProvider` | `AsyncNotifierProvider` | Past bookings, 10 per page via `startAfterDocument` |
| `bookingControllerProvider` | `AsyncNotifierProvider<…, String?>` | Book / cancel / force-cancel, with loading + error state |
| `authControllerProvider` | `AsyncNotifierProvider` | Login / sign-up / logout |

The room grid, My Bookings and the Admin tab are three views over the same `bookings` collection. All of them update live. SnackBars are triggered from widgets with `ref.listen` (in `HomeShell` and `LoginScreen`).

---

## Notes required by the brief

**Why the client-side email-domain check is not security.** The check in `EmailDomainValidator` only runs inside our app. Anyone can call the Firebase Auth REST endpoint (`accounts:signUp`) directly with the project's public API key and any email, and that skips the check completely. Real enforcement would need one of these: a *blocking function* (`beforeUserCreated`) that rejects other domains, Identity Platform tenant restrictions, or security rules that check `request.auth.token.email` (plus `email_verified`).

**No-show handling.** An `active` booking whose `slotEnd` has passed is *shown* as `expired`. This is done by `Booking.effectiveStatus(now)`, which re-evaluates every 30 s through `nowTickerProvider`. It does not count toward the 2-booking cap, and its slot is not treated as held. The stored status is not changed. **A production system would do this with a scheduled Cloud Function** that flips `status` to `expired`/`completed` on the server.

**Known limitation.** The 2-booking cap is enforced inside the transaction (server-side-equivalent). However, `activeBookingIds` lives on the user's own document, so a malicious client could edit that list to get around the cap. Fully server-side enforcement would need a Cloud Function or a rules-maintained counter.

---

## Security-rules test log

> **TODO (student):** run these yourself (Rules Playground or a real request from the app) and record the results.

| # | As | Attempt | Expected | Result |
|---|---|---|---|---|
| 1 | student | update own `users/{uid}` → `role: "admin"` | DENY | |
| 2 | student | update own `users/{uid}` → `name` | ALLOW | |
| 3 | student | create booking with `userId` = someone else | DENY | |
| 4 | student | update another student's booking → `cancelled` | DENY | |
| 5 | student | delete own booking | DENY | |
| 6 | admin | update another student's booking → `cancelled` | ALLOW | |
| 7 | student | overwrite a `slotLocks` doc whose booking is still active | DENY | |
| 8 | signed out | read `bookings` | DENY | |

---

## Personal design note — a bug I hit in the transaction

> **TODO (student):** write 3–5 bullet points **in your own words** about a bug *you* hit while building/testing the transaction, and how you found and fixed it. (The brief says generic answers are easy to spot, so this must come from your own experience doing the two-emulator test.)

-
-
-
