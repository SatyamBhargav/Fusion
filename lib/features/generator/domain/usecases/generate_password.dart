import 'dart:math' as math;

import '../../../../core/usecase/usecase.dart';
import '../entities/gen_options.dart';

const _upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
const _lower = 'abcdefghijkmnopqrstuvwxyz';
const _numbers = '23456789';
const _symbols = r'!@#$%&*?+=';

/// Cryptographically random password that always contains at least one
/// character from every enabled set.
class GeneratePassword implements UseCase<String, GenOptions> {
  GeneratePassword([math.Random? random])
    : _random = random ?? math.Random.secure();

  final math.Random _random;

  @override
  String call(GenOptions o) {
    final pools = <String>[
      if (o.upper) _upper,
      if (o.lower) _lower,
      if (o.numbers) _numbers,
      if (o.symbols) _symbols,
    ];
    if (pools.isEmpty) pools.add(_lower);
    final all = pools.join();
    final out = <String>[for (final p in pools) p[_random.nextInt(p.length)]];
    while (out.length < o.length) {
      out.add(all[_random.nextInt(all.length)]);
    }
    for (var i = out.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final t = out[i];
      out[i] = out[j];
      out[j] = t;
    }
    return out.take(o.length).join();
  }
}
