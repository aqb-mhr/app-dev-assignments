// Seeds the `rooms` collection with my personalized values.
//
//   Roll number 29184 -> N = 9184
//   capacity = (9184 mod 8) + 2 = 0 + 2 = 2
//   odd rooms -> floor 1, even rooms -> floor 2
//
// Usage (while Firestore is still in TEST MODE, i.e. before rules.txt):
//   dart run tool/seed_rooms.dart <firebase-project-id>
//
// Uses the Firestore REST API with plain dart:io - no extra packages.
// Running it twice is safe: it PATCHes fixed doc ids room1..room6.
import 'dart:convert';
import 'dart:io';

const rollNumber = 29184;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/seed_rooms.dart <firebase-project-id>');
    exit(64);
  }
  final projectId = args.first;
  final n = (rollNumber % 10000).toString().padLeft(4, '0');
  final capacity = (int.parse(n) % 8) + 2;

  final client = HttpClient();
  var failed = false;
  for (var i = 1; i <= 6; i++) {
    final room = {
      'name': 'Room-$n-$i',
      'floor': i.isOdd ? 1 : 2,
      'capacity': capacity,
    };
    final uri = Uri.parse('https://firestore.googleapis.com/v1/projects/'
        '$projectId/databases/(default)/documents/rooms/room$i');
    final req = await client.patchUrl(uri);
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({
      'fields': {
        'name': {'stringValue': room['name']},
        'floor': {'integerValue': '${room['floor']}'},
        'capacity': {'integerValue': '${room['capacity']}'},
      },
    }));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode == 200) {
      stdout.writeln('OK   room$i  $room');
    } else {
      failed = true;
      stderr.writeln('FAIL room$i  HTTP ${res.statusCode}: $body');
    }
  }
  client.close();
  if (failed) {
    stderr.writeln('\nIf you got 403 PERMISSION_DENIED: Firestore is not in '
        'test mode. Seed by hand in the console instead (values above), '
        'or temporarily allow writes, seed, then paste rules.txt.');
    exit(1);
  }
}
