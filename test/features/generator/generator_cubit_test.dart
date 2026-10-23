import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/features/generator/domain/usecases/generate_password.dart';
import 'package:fusion/features/generator/presentation/cubit/generator_cubit.dart';

void main() {
  GeneratorCubit build() =>
      GeneratorCubit(generatePassword: GeneratePassword());

  test('starts with a 16-character password', () {
    expect(build().state.password, hasLength(16));
  });

  test('a new length makes a new password', () {
    final cubit = build()..setLength(24);
    expect(cubit.state.options.length, 24);
    expect(cubit.state.password, hasLength(24));
  });

  test('refuses to turn off the last character type, every time', () async {
    final cubit = build();
    final effects = <GeneratorEffect>[];
    cubit.effects.listen(effects.add);
    expect(cubit.toggle(CharacterSet.upper), isTrue);
    expect(cubit.toggle(CharacterSet.lower), isTrue);
    expect(cubit.toggle(CharacterSet.numbers), isTrue);
    expect(cubit.toggle(CharacterSet.symbols), isFalse);
    expect(cubit.toggle(CharacterSet.symbols), isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(effects, [GeneratorEffect.keepOneType, GeneratorEffect.keepOneType]);
    expect(cubit.state.options.symbols, isTrue);
  });

  test('"Copied" shows for a moment', () {
    fakeAsync((async) {
      final cubit = build()..copied();
      expect(cubit.state.copied, isTrue);
      async.elapse(const Duration(milliseconds: 1700));
      expect(cubit.state.copied, isFalse);
    });
  });
}
