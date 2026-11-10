/// Short relative time such as "just now", "5m ago", "3h ago", "2d ago",
/// falling back to a date like "12 Oct 2026" after a week.
String timeAgo(DateTime? time, {DateTime? now}) {
  if (time == null) return 'just now';
  final reference = now ?? DateTime.now();
  final diff = reference.difference(time);

  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatDate(time);
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "12 Oct 2026, 3:05 PM"-style date, without pulling in the intl package.
String formatDate(DateTime time, {bool withTime = false}) {
  final local = time.toLocal();
  final date = '${local.day} ${_months[local.month - 1]} ${local.year}';
  if (!withTime) return date;
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '$date, $hour12:$minute $period';
}
