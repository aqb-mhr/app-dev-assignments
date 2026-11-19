class Room {
  const Room({
    required this.id,
    required this.name,
    required this.floor,
    required this.capacity,
  });

  final String id;
  final String name;
  final int floor;
  final int capacity;

  @override
  bool operator ==(Object other) => other is Room && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
