import 'dart:math' as math;

final _rng = math.Random();

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_rng.nextInt(0x7fffffff).toRadixString(36)}';

String monogramOf(String text) {
  final t = text.trim();
  if (t.isEmpty) return '?';
  return t.substring(0, 1).toUpperCase();
}

String relativeTime(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  if (d.inDays == 1) return 'Yesterday';
  if (d.inDays < 30) return '${d.inDays} days ago';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${t.day} ${months[t.month - 1]} ${t.year}';
}

bool looksLikeEmail(String s) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());
