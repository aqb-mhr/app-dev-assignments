import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lost_item.dart';

/// One row of the assignment's seed table.
class SeedItem {
  const SeedItem({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.status,
    required this.description,
    required this.postedBy,
  });

  /// Fixed document id, so seeding twice never creates duplicates.
  final String id;
  final String title;
  final String category;
  final String location;
  final ItemStatus status;
  final String description;
  final String postedBy;

  Map<String, dynamic> toFirestore({required DateTime createdAt}) {
    return <String, dynamic>{
      'title': title,
      'category': category,
      'location': location,
      'status': status.label,
      'description': description,
      'postedBy': postedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// The 8 sample items from the assignment brief.
const List<SeedItem> sampleItems = [
  SeedItem(
    id: 'seed-black-backpack',
    title: 'Black Backpack',
    category: 'Bag',
    location: 'MCC Cafeteria',
    status: ItemStatus.found,
    description:
        'Plain black backpack left under a table near the juice counter. '
        'There is a notebook and a pencil case inside. Describe the keychain '
        'on the zip to claim it.',
    postedBy: 'Hamza Siddiqui',
  ),
  SeedItem(
    id: 'seed-blue-water-bottle',
    title: 'Blue Water Bottle',
    category: 'Accessory',
    location: 'Library, 2nd Floor',
    status: ItemStatus.found,
    description:
        'Steel water bottle, dark blue with a few stickers, found at the '
        'quiet-study desks by the window. Handed over to the library front '
        'desk.',
    postedBy: 'Sana Tariq',
  ),
  SeedItem(
    id: 'seed-student-id-m-ali',
    title: 'Student ID Card — M. Ali',
    category: 'ID Card',
    location: 'Main Gate',
    status: ItemStatus.found,
    description:
        'IBA student card picked up near the security booth at the main gate. '
        'The owner can collect it from the security office with their ERP '
        'number.',
    postedBy: 'Usman Khan',
  ),
  SeedItem(
    id: 'seed-dell-laptop-charger',
    title: 'Laptop Charger (Dell)',
    category: 'Electronics',
    location: 'Room 301',
    status: ItemStatus.lost,
    description:
        '65W Dell charger with a round barrel tip. Probably left plugged in '
        'under the back-row desks after the 11:30 class. Please message me if '
        'you find it.',
    postedBy: 'Fatima Noor',
  ),
  SeedItem(
    id: 'seed-black-umbrella',
    title: 'Umbrella (Black)',
    category: 'Accessory',
    location: 'Admin Block',
    status: ItemStatus.lost,
    description:
        'Folding black umbrella with a curved wooden handle. Left near the '
        'Admin Block entrance during Monday\'s rain.',
    postedBy: 'Bilal Ahmed',
  ),
  SeedItem(
    id: 'seed-bunch-of-keys',
    title: 'Bunch of Keys',
    category: 'Keys',
    location: 'Parking Lot',
    status: ItemStatus.found,
    description:
        'Three keys on a red lanyard with a small car remote, found near the '
        'second row of the student parking lot.',
    postedBy: 'Zainab Raza',
  ),
  SeedItem(
    id: 'seed-calculus-textbook',
    title: 'Calculus Textbook',
    category: 'Book',
    location: 'Student Lounge',
    status: ItemStatus.lost,
    description:
        'Thick calculus textbook with my name written inside the front cover '
        'and lots of coloured sticky notes. Last seen on the sofas in the '
        'Student Lounge.',
    postedBy: 'Ahmed Raza',
  ),
  SeedItem(
    id: 'seed-grey-jacket',
    title: 'Grey Jacket',
    category: 'Clothing',
    location: 'Auditorium',
    status: ItemStatus.found,
    description:
        'Grey zip-up jacket, size M, left on a third-row seat after Friday\'s '
        'event. Kept at the auditorium front office.',
    postedBy: 'Mariam Shah',
  ),
];
