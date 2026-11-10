import 'package:flutter_test/flutter_test.dart';
import 'package:lost_found/utils/time_ago.dart';

void main() {
  final now = DateTime(2026, 11, 10, 12);

  test('timeAgo buckets', () {
    expect(timeAgo(null, now: now), 'just now');
    expect(timeAgo(now.subtract(const Duration(seconds: 20)), now: now),
        'just now');
    expect(timeAgo(now.subtract(const Duration(minutes: 5)), now: now),
        '5m ago');
    expect(timeAgo(now.subtract(const Duration(hours: 3)), now: now),
        '3h ago');
    expect(timeAgo(now.subtract(const Duration(days: 2)), now: now),
        '2d ago');
    expect(timeAgo(DateTime(2026, 10, 12), now: now), '12 Oct 2026');
  });

  test('formatDate with time uses a 12-hour clock', () {
    expect(
      formatDate(DateTime(2026, 11, 3, 15, 5), withTime: true),
      '3 Nov 2026, 3:05 PM',
    );
    expect(
      formatDate(DateTime(2026, 11, 3, 0, 30), withTime: true),
      '3 Nov 2026, 12:30 AM',
    );
  });
}
