import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_found/data/item_repository.dart';
import 'package:lost_found/data/seed_data.dart';
import 'package:lost_found/models/lost_item.dart';

void main() {
  late FakeFirebaseFirestore db;
  late ItemRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = ItemRepository(db);
  });

  group('seedSampleItems', () {
    test('adds the 8 sample items from the brief', () async {
      expect(await repo.seedSampleItems(), 8);

      final docs = await db.collection('items').get();
      expect(docs.size, 8);
      final titles = docs.docs.map((d) => d['title']).toSet();
      expect(titles, containsAll(['Black Backpack', 'Grey Jacket']));
    });

    test('is idempotent and never resets a changed status', () async {
      await repo.seedSampleItems();
      await repo.markAsClaimed(sampleItems.first.id);

      expect(await repo.seedSampleItems(), 0);

      final docs = await db.collection('items').get();
      expect(docs.size, 8);
      final first = await db.doc('items/${sampleItems.first.id}').get();
      expect(first['status'], 'Claimed');
    });
  });

  test('watchItems streams the collection newest first', () async {
    await repo.seedSampleItems();

    final items = await repo.watchItems().first;

    expect(items, hasLength(8));
    expect(items.first.title, 'Black Backpack');
    expect(items.last.title, 'Grey Jacket');
  });

  test('watchItems emits again when an item is added', () async {
    final stream = repo.watchItems();
    final expectation = expectLater(
      stream.map((items) => items.map((i) => i.title).toList()),
      emitsThrough(['Blue Umbrella']),
    );

    await repo.addItem(
      title: '  Blue Umbrella ',
      category: 'Accessory',
      location: 'Library',
      status: ItemStatus.found,
      description: 'Small',
      postedBy: 'Ali',
    );

    await expectation;
  });

  group('markAsClaimed (transaction)', () {
    late String id;

    setUp(() async {
      id = await repo.addItem(
        title: 'Bunch of Keys',
        category: 'Keys',
        location: 'Parking Lot',
        status: ItemStatus.found,
        description: 'Red lanyard',
        postedBy: 'Zainab',
      );
    });

    test('claims a Found item and records what it was before', () async {
      expect(await repo.markAsClaimed(id), ClaimOutcome.claimed);

      final doc = await db.doc('items/$id').get();
      expect(doc['status'], 'Claimed');
      expect(doc['previousStatus'], 'Found');
      expect(doc['claimedAt'], isNotNull);
    });

    test('a second claim is rejected without rewriting the doc', () async {
      await repo.markAsClaimed(id);
      final firstClaimedAt = (await db.doc('items/$id').get())['claimedAt'];

      expect(await repo.markAsClaimed(id), ClaimOutcome.alreadyClaimed);

      final doc = await db.doc('items/$id').get();
      expect(doc['previousStatus'], 'Found');
      expect(doc['claimedAt'], firstClaimedAt);
    });

    test('simultaneous taps on one device share a single transaction',
        () async {
      final results = await Future.wait([
        repo.markAsClaimed(id),
        repo.markAsClaimed(id),
        repo.markAsClaimed(id),
      ]);

      expect(results, everyElement(ClaimOutcome.claimed));
      final doc = await db.doc('items/$id').get();
      expect(doc['status'], 'Claimed');
      expect(doc['previousStatus'], 'Found');
    });

    test('reports notFound for a deleted item', () async {
      await repo.deleteItem(id);
      expect(await repo.markAsClaimed(id), ClaimOutcome.notFound);
    });
  });

  test('watchItem follows status changes and emits null on delete', () async {
    final id = await repo.addItem(
      title: 'Grey Jacket',
      category: 'Clothing',
      location: 'Auditorium',
      status: ItemStatus.found,
      description: 'Size M',
      postedBy: 'Mariam',
    );

    final expectation = expectLater(
      repo.watchItem(id).map((item) => item?.status),
      emitsInOrder([ItemStatus.found, ItemStatus.claimed, null]),
    );

    await Future<void>.delayed(Duration.zero);
    // Simulate another device / the console changing the document.
    await db.doc('items/$id').update({'status': 'Claimed'});
    await Future<void>.delayed(Duration.zero);
    await repo.deleteItem(id);

    await expectation;
  });

  test('restoreItem brings a deleted item back under the same id', () async {
    await repo.seedSampleItems();
    final original = (await repo.watchItems().first).first;

    await repo.deleteItem(original.id);
    expect((await db.doc('items/${original.id}').get()).exists, isFalse);

    await repo.restoreItem(original);
    final restored = await db.doc('items/${original.id}').get();
    expect(restored.exists, isTrue);
    expect(restored['title'], original.title);
  });
}
