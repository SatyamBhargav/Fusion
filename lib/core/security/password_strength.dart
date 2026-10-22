import 'dart:math' as math;

class Strength {
  const Strength(this.score, this.label);

  /// 0 = empty, 1 = weak, 2 = fair, 3 = strong, 4 = very strong.
  final int score;
  final String label;
}

const _common = [
  'password',
  'qwerty',
  '123456',
  '111111',
  'letmein',
  'welcome',
  'iloveyou',
  'admin',
  'abc123',
  'monkey',
  'dragon',
  'football',
];

Strength strengthOf(String pw) {
  if (pw.isEmpty) return const Strength(0, '');
  final lower = pw.toLowerCase();
  if (pw.length < 8 || _common.any(lower.contains)) {
    return const Strength(1, 'Weak');
  }
  var pool = 0;
  if (RegExp('[a-z]').hasMatch(pw)) pool += 26;
  if (RegExp('[A-Z]').hasMatch(pw)) pool += 26;
  if (RegExp('[0-9]').hasMatch(pw)) pool += 10;
  if (RegExp('[^A-Za-z0-9]').hasMatch(pw)) pool += 32;
  final bits = pw.length * (math.log(math.max(pool, 2)) / math.ln2);
  if (bits < 36) return const Strength(1, 'Weak');
  if (bits < 56) return const Strength(2, 'Fair');
  if (bits < 80) return const Strength(3, 'Strong');
  return const Strength(4, 'Very strong');
}
