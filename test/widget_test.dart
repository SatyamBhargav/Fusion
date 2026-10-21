import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/services/password_generator.dart';
import 'package:fusion/services/vault_item.dart';

void main() {
  group('generatePassword', () {
    test('respects length', () {
      for (final n in [8, 16, 32, 40]) {
        expect(generatePassword(GenOptions(length: n)).length, n);
      }
    });

    test('contains every enabled character set', () {
      for (var i = 0; i < 50; i++) {
        final pw = generatePassword(const GenOptions(length: 8));
        expect(RegExp('[A-Z]').hasMatch(pw), isTrue);
        expect(RegExp('[a-z]').hasMatch(pw), isTrue);
        expect(RegExp('[0-9]').hasMatch(pw), isTrue);
        expect(RegExp('[^A-Za-z0-9]').hasMatch(pw), isTrue);
      }
    });

    test('digits only when only numbers enabled', () {
      final pw = generatePassword(
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

  group('strengthOf', () {
    test('scores', () {
      expect(strengthOf('').score, 0);
      expect(strengthOf('abc').score, 1);
      expect(strengthOf('v9#Lp2!xQe7@Wm4K').label, 'Very strong');
    });
  });

  test('VaultItem JSON round-trip', () {
    final item = VaultItem(
      id: '1',
      name: 'Dribbble',
      website: 'dribbble.com',
      username: 'aanya@example.com',
      password: '',
      note: '',
      favourite: true,
      kind: LoginKind.social,
      provider: 'apple',
      updatedAt: DateTime(2026, 1, 1),
    );
    final back = VaultItem.fromJson(item.toJson());
    expect(back.kind, LoginKind.social);
    expect(back.subtitle, 'via Apple');
    expect(back.favourite, isTrue);
  });
}
