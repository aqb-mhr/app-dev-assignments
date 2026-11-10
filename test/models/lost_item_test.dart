import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_found/models/lost_item.dart';

void main() {
  group('ItemStatus.fromLabel', () {
    test('parses stored labels', () {
      expect(ItemStatus.fromLabel('Lost'), ItemStatus.lost);
      expect(ItemStatus.fromLabel('Found'), ItemStatus.found);
      expect(ItemStatus.fromLabel('Claimed'), ItemStatus.claimed);
    });

    test('ignores case and whitespace from console edits', () {
      expect(ItemStatus.fromLabel(' claimed '), ItemStatus.claimed);
      expect(ItemStatus.fromLabel('FOUND'), ItemStatus.found);
    });

    test('falls back to Lost for unknown or missing values', () {
      expect(ItemStatus.fromLabel(null), ItemStatus.lost);
      expect(ItemStatus.fromLabel('misplaced'), ItemStatus.lost);
    });

    test('new posts can only start as Lost or Found', () {
      expect(ItemStatus.postable, [ItemStatus.lost, ItemStatus.found]);
    });
  });

  group('LostItem.fromMap', () {
    test('reads every field', () {
      final created = DateTime(2026, 11, 3, 10, 30);
      final item = LostItem.fromMap('abc', {
        'title': 'Grey Jacket',
        'category': 'Clothing',
        'location': 'Auditorium',
        'status': 'Found',
        'description': 'Size M',
        'postedBy': 'Mariam',
        'createdAt': Timestamp.fromDate(created),
      });

      expect(item.id, 'abc');
      expect(item.title, 'Grey Jacket');
      expect(item.category, 'Clothing');
      expect(item.location, 'Auditorium');
      expect(item.status, ItemStatus.found);
      expect(item.description, 'Size M');
      expect(item.postedBy, 'Mariam');
      expect(item.createdAt, created);
      expect(item.claimedAt, isNull);
      expect(item.isClaimed, isFalse);
    });

    test('tolerates a half-filled document', () {
      final item = LostItem.fromMap('x', {'title': '  Keys  '});

      expect(item.title, 'Keys');
      expect(item.location, '');
      expect(item.status, ItemStatus.lost);
      expect(item.createdAt, isNull);
    });
  });

  test('toFirestore keeps the original timestamps for undo', () {
    final created = DateTime(2026, 11, 1, 9);
    final claimed = DateTime(2026, 11, 2, 9);
    final item = LostItem(
      id: 'abc',
      title: 'Umbrella (Black)',
      category: 'Accessory',
      location: 'Admin Block',
      status: ItemStatus.claimed,
      description: 'Folding',
      postedBy: 'Bilal',
      createdAt: created,
      claimedAt: claimed,
    );

    final map = item.toFirestore();

    expect(map['status'], 'Claimed');
    expect((map['createdAt'] as Timestamp).toDate(), created);
    expect((map['claimedAt'] as Timestamp).toDate(), claimed);
  });
}
