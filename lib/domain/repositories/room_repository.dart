import '../entities/room.dart';

abstract interface class RoomRepository {
  Stream<List<Room>> watchRooms();
}
