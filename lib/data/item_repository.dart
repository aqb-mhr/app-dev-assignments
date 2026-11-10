import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/item_filter.dart';
import '../models/lost_item.dart';

/// All Firestore access for the `items` collection lives here, so screens
/// never touch collection paths or field names directly.
class ItemRepository {
  ItemRepository(this._db);

  final FirebaseFirestore _db;

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

  Future<void> deleteItem(String id) => _items.doc(id).delete();

  /// Writes a deleted item back under its original id (used by "Undo").
  Future<void> restoreItem(LostItem item) =>
      _items.doc(item.id).set(item.toFirestore());
}
