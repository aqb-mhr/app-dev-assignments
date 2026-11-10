import '../models/lost_item.dart';

/// Applies the title search and status filter together.
///
/// Firestore has no substring search, so filtering happens on the client
/// over the live snapshot. A null [status] means "All".
List<LostItem> filterItems(
  Iterable<LostItem> items, {
  String query = '',
  ItemStatus? status,
}) {
  final needle = query.trim().toLowerCase();
  return items.where((item) {
    final matchesStatus = status == null || item.status == status;
    final matchesQuery =
        needle.isEmpty || item.title.toLowerCase().contains(needle);
    return matchesStatus && matchesQuery;
  }).toList();
}

/// Number of items per status, used for the counts on the filter chips.
Map<ItemStatus, int> countByStatus(Iterable<LostItem> items) {
  final counts = {for (final status in ItemStatus.values) status: 0};
  for (final item in items) {
    counts[item.status] = counts[item.status]! + 1;
  }
  return counts;
}

/// Newest first. Items without a timestamp yet (a just-posted item whose
/// server timestamp is pending) go on top, ties broken by title.
List<LostItem> sortNewestFirst(Iterable<LostItem> items) {
  final sorted = items.toList();
  sorted.sort((a, b) {
    final aDate = a.createdAt;
    final bDate = b.createdAt;
    if (aDate == null && bDate != null) return -1;
    if (aDate != null && bDate == null) return 1;
    if (aDate != null && bDate != null) {
      final byDate = bDate.compareTo(aDate);
      if (byDate != 0) return byDate;
    }
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });
  return sorted;
}
