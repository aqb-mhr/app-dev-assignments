import 'package:flutter_test/flutter_test.dart';
import 'package:lost_found/logic/item_filter.dart';
import 'package:lost_found/models/lost_item.dart';

LostItem _item(
  String id,
  String title,
  ItemStatus status, {
  DateTime? createdAt,
}) {
  return LostItem(
    id: id,
    title: title,
    category: 'Other',
    location: 'Campus',
    status: status,
    description: '',
    postedBy: 'Test',
    createdAt: createdAt,
  );
}

void main() {
  final items = [
    _item('1', 'Black Backpack', ItemStatus.found),
    _item('2', 'Blue Water Bottle', ItemStatus.found),
    _item('3', 'Laptop Charger (Dell)', ItemStatus.lost),
    _item('4', 'Umbrella (Black)', ItemStatus.lost),
    _item('5', 'Grey Jacket', ItemStatus.claimed),
  ];

  List<String> ids(List<LostItem> list) => list.map((i) => i.id).toList();

  group('filterItems', () {
    test('returns everything with no query and "All"', () {
      expect(filterItems(items), hasLength(5));
    });

    test('searches titles case-insensitively and trims the query', () {
      expect(ids(filterItems(items, query: '  BLACK ')), ['1', '4']);
    });

    test('filters by status', () {
      expect(ids(filterItems(items, status: ItemStatus.lost)), ['3', '4']);
      expect(ids(filterItems(items, status: ItemStatus.claimed)), ['5']);
    });

    test('combines search and status filter', () {
      expect(
        ids(filterItems(items, query: 'black', status: ItemStatus.found)),
        ['1'],
      );
      expect(
        filterItems(items, query: 'jacket', status: ItemStatus.lost),
        isEmpty,
      );
    });
  });

  test('countByStatus counts every status, including zero', () {
    final counts = countByStatus(items.take(2));
    expect(counts, {
      ItemStatus.lost: 0,
      ItemStatus.found: 2,
      ItemStatus.claimed: 0,
    });
  });

  test('sortNewestFirst puts pending timestamps first, then newest', () {
    final sorted = sortNewestFirst([
      _item('old', 'A', ItemStatus.lost, createdAt: DateTime(2026, 1, 1)),
      _item('pending', 'B', ItemStatus.lost),
      _item('new', 'C', ItemStatus.lost, createdAt: DateTime(2026, 6, 1)),
    ]);
    expect(ids(sorted), ['pending', 'new', 'old']);
  });
}
