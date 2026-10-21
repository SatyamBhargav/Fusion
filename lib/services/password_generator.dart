import 'dart:math' as math;

const _upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
const _lower = 'abcdefghijkmnopqrstuvwxyz';
const _numbers = '23456789';
const _symbols = r'!@#$%&*?+=';

class GenOptions {
  const GenOptions({
    this.length = 16,
    this.upper = true,
    this.lower = true,
    this.numbers = true,
    this.symbols = true,
  });

  final int length;
  final bool upper;
  final bool lower;
  final bool numbers;
  final bool symbols;

  int get enabledCount =>
      [upper, lower, numbers, symbols].where((e) => e).length;

  GenOptions copyWith({
    int? length,
    bool? upper,
    bool? lower,
    bool? numbers,
    bool? symbols,
  }) {
    return GenOptions(
      length: length ?? this.length,
      upper: upper ?? this.upper,
      lower: lower ?? this.lower,
      numbers: numbers ?? this.numbers,
      symbols: symbols ?? this.symbols,
    );
  }
}

final math.Random _secure = math.Random.secure();

/// Cryptographically random password that always contains at least one
/// character from every enabled set.
String generatePassword(GenOptions o) {
  final pools = <String>[
    if (o.upper) _upper,
    if (o.lower) _lower,
    if (o.numbers) _numbers,
    if (o.symbols) _symbols,
  ];
  if (pools.isEmpty) pools.add(_lower);
  final all = pools.join();
  final out = <String>[for (final p in pools) p[_secure.nextInt(p.length)]];
  while (out.length < o.length) {
    out.add(all[_secure.nextInt(all.length)]);
  }
  for (var i = out.length - 1; i > 0; i--) {
    final j = _secure.nextInt(i + 1);
    final t = out[i];
    out[i] = out[j];
    out[j] = t;
  }
  return out.take(o.length).join();
}

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
