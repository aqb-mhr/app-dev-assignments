import 'package:cloud_firestore/cloud_firestore.dart';

/// Where an item is in its lifecycle. [label] is the exact value stored in
/// the `status` field of a Firestore document.
enum ItemStatus {
  lost('Lost'),
  found('Found'),
  claimed('Claimed');

  const ItemStatus(this.label);

  final String label;

  /// Statuses a brand new post can start with. Items only become
  /// [claimed] through the "Mark as Claimed" transaction.
  static const List<ItemStatus> postable = [lost, found];

  /// Parses a stored value. Case and surrounding spaces are ignored so items
  /// typed in by hand in the Firebase console still map correctly.
  static ItemStatus fromLabel(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    for (final status in values) {
      if (status.label.toLowerCase() == normalized) return status;
    }
    return lost;
  }
}

/// Categories offered by the "Add Item" form.
abstract final class ItemCategories {
  static const List<String> all = [
    'Bag',
    'Accessory',
    'ID Card',
    'Electronics',
    'Keys',
    'Book',
    'Clothing',
    'Other',
  ];
}

/// One document in the `items` collection.
class LostItem {
  const LostItem({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.status,
    required this.description,
    required this.postedBy,
    this.createdAt,
    this.claimedAt,
  });

  factory LostItem.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return LostItem.fromMap(
      snapshot.id,
      snapshot.data() ?? const <String, dynamic>{},
    );
  }

  /// Tolerant of missing fields, so a half-filled document added in the
  /// console never crashes the list.
  factory LostItem.fromMap(String id, Map<String, dynamic> data) {
    return LostItem(
      id: id,
      title: _string(data['title']),
      category: _string(data['category']),
      location: _string(data['location']),
      status: ItemStatus.fromLabel(data['status']),
      description: _string(data['description']),
      postedBy: _string(data['postedBy']),
      createdAt: _date(data['createdAt']),
      claimedAt: _date(data['claimedAt']),
    );
  }

  final String id;
  final String title;
  final String category;
  final String location;
  final ItemStatus status;
  final String description;
  final String postedBy;

  /// Null while a new item's server timestamp is still pending.
  final DateTime? createdAt;
  final DateTime? claimedAt;

  bool get isClaimed => status == ItemStatus.claimed;

  /// Full document body, used when restoring a deleted item (undo).
  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'title': title,
      'category': category,
      'location': location,
      'status': status.label,
      'description': description,
      'postedBy': postedBy,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      if (claimedAt != null) 'claimedAt': Timestamp.fromDate(claimedAt!),
    };
  }

  static String _string(Object? value) => value?.toString().trim() ?? '';

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
