import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_found/app.dart';
import 'package:lost_found/data/item_repository.dart';

void main() {
  late FakeFirebaseFirestore db;
  late ItemRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = ItemRepository(db);
  });

  /// Tall surface so all 8 cards are built at once.
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(LostFoundApp(repository: repo));
    await tester.pumpAndSettle();
  }

  testWidgets('empty collection offers to load the sample items',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('Nothing posted yet'), findsOneWidget);
    await tester.tap(find.text('Load sample items'));
    await tester.pumpAndSettle();

    expect(find.text('Black Backpack'), findsOneWidget);
    expect(find.text('Grey Jacket'), findsOneWidget);
  });

  testWidgets('search and status filter work together', (tester) async {
    await repo.seedSampleItems();
    await pumpApp(tester);

    expect(find.text('All  8'), findsOneWidget);
    expect(find.text('Found  5'), findsOneWidget);
    expect(find.text('Lost  3'), findsOneWidget);

    // Search alone.
    await tester.enterText(find.byKey(const ValueKey('search-field')), 'black');
    await tester.pumpAndSettle();
    expect(find.text('Black Backpack'), findsOneWidget);
    expect(find.text('Umbrella (Black)'), findsOneWidget);
    expect(find.text('Grey Jacket'), findsNothing);

    // Search + Lost filter narrows it to the umbrella.
    await tester.tap(find.byKey(const ValueKey('filter-lost')));
    await tester.pumpAndSettle();
    expect(find.text('Umbrella (Black)'), findsOneWidget);
    expect(find.text('Black Backpack'), findsNothing);

    // Nothing is claimed yet.
    await tester.tap(find.byKey(const ValueKey('filter-claimed')));
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Grey Jacket'), findsOneWidget);
  });

  testWidgets('list updates live when Firestore changes', (tester) async {
    await repo.seedSampleItems();
    await pumpApp(tester);

    await db.doc('items/seed-grey-jacket').update({'status': 'Claimed'});
    await tester.pumpAndSettle();

    expect(find.text('Claimed  1'), findsOneWidget);
    expect(find.text('Found  4'), findsOneWidget);
  });

  testWidgets('detail screen reflects a claim made elsewhere',
      (tester) async {
    await repo.seedSampleItems();
    await pumpApp(tester);

    await tester.tap(find.text('Bunch of Keys'));
    await tester.pumpAndSettle();
    expect(find.text('Mark as Claimed'), findsOneWidget);
    expect(find.text('Three keys on a red lanyard with a small car remote, '
        'found near the second row of the student parking lot.'),
        findsOneWidget);

    // Another device claims it.
    await repo.markAsClaimed('seed-bunch-of-keys');
    await tester.pumpAndSettle();

    expect(find.text('Already claimed'), findsOneWidget);
    expect(find.byKey(const ValueKey('claimed-banner')), findsOneWidget);
  });

  testWidgets('mark as claimed from the detail screen', (tester) async {
    await repo.seedSampleItems();
    await pumpApp(tester);

    await tester.tap(find.text('Grey Jacket'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('claim-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-claim')));
    await tester.pumpAndSettle();

    expect(find.text('Already claimed'), findsOneWidget);
    final doc = await db.doc('items/seed-grey-jacket').get();
    expect(doc['status'], 'Claimed');
  });

  testWidgets('delete from the detail screen returns to the list',
      (tester) async {
    await repo.seedSampleItems();
    await pumpApp(tester);

    await tester.tap(find.text('Calculus Textbook'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-item')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-delete')));
    await tester.pumpAndSettle();

    expect(find.text('All  7'), findsOneWidget);
    expect(find.text('Deleted "Calculus Textbook"'), findsOneWidget);
    expect((await db.doc('items/seed-calculus-textbook').get()).exists,
        isFalse);
  });

  testWidgets('add item form writes a new item', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('add-item-fab')));
    await tester.pumpAndSettle();

    // Submitting empty shows validation errors.
    await tester.tap(find.byKey(const ValueKey('submit-item')));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a title'), findsOneWidget);

    await tester.tap(find.text('I lost something'));
    await tester.enterText(
        find.byKey(const ValueKey('field-title')), 'Red Scarf');
    await tester.tap(find.byKey(const ValueKey('field-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clothing').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('field-location')), 'Tabba Building');
    await tester.enterText(
        find.byKey(const ValueKey('field-description')), 'Wool, knitted');
    await tester.enterText(
        find.byKey(const ValueKey('field-posted-by')), 'Ali');
    await tester.tap(find.byKey(const ValueKey('submit-item')));
    await tester.pumpAndSettle();

    expect(find.text('Red Scarf'), findsOneWidget);
    final docs = await db.collection('items').get();
    expect(docs.size, 1);
    expect(docs.docs.single['status'], 'Lost');
    expect(docs.docs.single['category'], 'Clothing');
  });
}
