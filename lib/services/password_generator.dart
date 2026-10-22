import 'dart:math' as math;

export '../core/security/password_strength.dart';

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
