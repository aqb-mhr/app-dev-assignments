import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/room.dart';
import '../domain/repositories/room_repository.dart';

class FirestoreRoomRepository implements RoomRepository {
  FirestoreRoomRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<List<Room>> watchRooms() {
    return _db.collection('rooms').orderBy('name').snapshots().map(
          (s) => s.docs.map((doc) {
            final d = doc.data();
            return Room(
              id: doc.id,
              name: d['name'] as String? ?? doc.id,
              floor: (d['floor'] as num?)?.toInt() ?? 0,
              capacity: (d['capacity'] as num?)?.toInt() ?? 0,
            );
          }).toList(),
        );
  }
}
