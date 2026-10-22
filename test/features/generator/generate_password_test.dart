import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/core/security/password_strength.dart';
import 'package:fusion/features/generator/domain/entities/gen_options.dart';
import 'package:fusion/features/generator/domain/usecases/generate_password.dart';

void main() {
  final generate = GeneratePassword();

  group('GeneratePassword', () {
    test('respects length', () {
      for (final n in [8, 16, 32, 40]) {
        expect(generate(GenOptions(length: n)).length, n);
      }
    });

    test('contains every enabled character set', () {
      for (var i = 0; i < 50; i++) {
        final pw = generate(const GenOptions(length: 8));
        expect(RegExp('[A-Z]').hasMatch(pw), isTrue);
        expect(RegExp('[a-z]').hasMatch(pw), isTrue);
        expect(RegExp('[0-9]').hasMatch(pw), isTrue);
        expect(RegExp('[^A-Za-z0-9]').hasMatch(pw), isTrue);
      }
    });

    test('digits only when only numbers enabled', () {
      final pw = generate(
        const GenOptions(
          length: 20,
          upper: false,
          lower: false,
          symbols: false,
        ),
      );
      expect(RegExp(r'^[0-9]+$').hasMatch(pw), isTrue);
    });
  });

  test('strengthOf scores', () {
    expect(strengthOf('').score, 0);
    expect(strengthOf('abc').score, 1);
    expect(strengthOf('v9#Lp2!xQe7@Wm4K').label, 'Very strong');
  });
}
