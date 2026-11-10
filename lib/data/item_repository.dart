import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/item_filter.dart';
import '../models/lost_item.dart';
import 'seed_data.dart';

/// Result of a "Mark as Claimed" attempt.
enum ClaimOutcome {
  /// This call changed the item to Claimed.
  claimed,

  /// Someone else claimed it first; nothing was written.
  alreadyClaimed,

  /// The item was deleted before the claim went through.
  notFound,
}

/// All Firestore access for the `items` collection lives here, so screens
/// never touch collection paths or field names directly.
class ItemRepository {
  ItemRepository(this._db);

  final FirebaseFirestore _db;

  /// Claims currently running on this device, keyed by item id.
  final Map<String, Future<ClaimOutcome>> _claimsInFlight = {};

  static const String collectionPath = 'items';

  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection(collectionPath);

  /// Live list of every item, newest first. Backed by `.snapshots()`, so
  /// edits from other devices or the Firebase console arrive automatically.
  ///
  /// Sorting is done client-side instead of with `orderBy('createdAt')`
  /// because Firestore drops documents that lack the ordered field, and items
  /// typed into the console by hand often have no `createdAt`.
  Stream<List<LostItem>> watchItems() {
    return _items.snapshots().map(
          (snapshot) =>
              sortNewestFirst(snapshot.docs.map(LostItem.fromSnapshot)),
        );
  }

  /// Live view of a single item. Emits null once the item is deleted.
  Stream<LostItem?> watchItem(String id) {
    return _items.doc(id).snapshots().map(
          (snapshot) =>
              snapshot.exists ? LostItem.fromSnapshot(snapshot) : null,
        );
  }

  /// Posts a new item and returns its document id.
  Future<String> addItem({
    required String title,
    required String category,
    required String location,
    required ItemStatus status,
    required String description,
    required String postedBy,
  }) async {
    final ref = await _items.add(<String, dynamic>{
      'title': title.trim(),
      'category': category.trim(),
      'location': location.trim(),
      'status': status.label,
      'description': description.trim(),
      'postedBy': postedBy.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Marks an item as Claimed inside a Firestore transaction.
  ///
  /// The transaction reads the current status and only writes if the item
  /// is still Lost or Found. If two people tap "Claimed" at the same moment,
  /// Firestore detects that the document changed under one of them and
  /// retries that transaction; on retry it reads "Claimed" and returns
  /// [ClaimOutcome.alreadyClaimed] without writing. Exactly one claim wins
  /// and `claimedAt` / `previousStatus` are written exactly once.
  ///
  /// Repeated taps on the same device share one transaction, which saves a
  /// round trip on top of the server-side guarantee.
  Future<ClaimOutcome> markAsClaimed(String id) {
    final pending = _claimsInFlight[id];
    if (pending != null) return pending;

    final claim = _runClaimTransaction(id)
        .whenComplete(() => _claimsInFlight.remove(id));
    _claimsInFlight[id] = claim;
    return claim;
  }

  Future<ClaimOutcome> _runClaimTransaction(String id) {
    final ref = _items.doc(id);
    return _db.runTransaction<ClaimOutcome>((transaction) async {
      // All reads must happen before any writes in a transaction.
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return ClaimOutcome.notFound;

      final current = ItemStatus.fromLabel(snapshot.data()?['status']);
      if (current == ItemStatus.claimed) return ClaimOutcome.alreadyClaimed;

      transaction.update(ref, <String, dynamic>{
        'status': ItemStatus.claimed.label,
        'previousStatus': current.label,
        'claimedAt': FieldValue.serverTimestamp(),
      });
      return ClaimOutcome.claimed;
    });
  }

  Future<void> deleteItem(String id) => _items.doc(id).delete();

  /// Writes a deleted item back under its original id (used by "Undo").
  Future<void> restoreItem(LostItem item) =>
      _items.doc(item.id).set(item.toFirestore());

  /// One-time seed of the 8 sample items from the brief.
  ///
  /// Each sample has a fixed document id and only missing ones are written,
  /// so running it again never duplicates items or resets a status someone
  /// already changed. Returns how many items were added.
  Future<int> seedSampleItems({DateTime? now}) async {
    final base = now ?? DateTime.now();
    final refs = [for (final seed in sampleItems) _items.doc(seed.id)];
    final existing = await Future.wait(refs.map((ref) => ref.get()));

    final batch = _db.batch();
    var added = 0;
    for (var i = 0; i < sampleItems.length; i++) {
      if (existing[i].exists) continue;
      // Stagger timestamps so the list shows a realistic "posted 5h ago"
      // spread, with the first row of the table as the newest.
      final createdAt = base.subtract(Duration(hours: 1 + i * 5));
      batch.set(refs[i], sampleItems[i].toFirestore(createdAt: createdAt));
      added++;
    }
    if (added > 0) await batch.commit();
    return added;
  }
}
