import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/core/security/hashing.dart';

void main() {
  group('stretchHash', () {
    test('matches the hash existing accounts were created with', () {
      // Pinned from the original AuthService._hashWorker so stored master
      // password hashes keep verifying after the move.
      expect(
        stretchHash('c2FsdHNhbHRzYWx0c2FsdA', 'correct horse'),
        'upHRdgO/QHkziDqCg2ImqCU0fU/xCI77gk3FYuCn7WM=',
      );
    });

    test('depends on the salt', () {
      expect(
        stretchHash('salt-a', '123456'),
        isNot(stretchHash('salt-b', '123456')),
      );
    });

    test('runs in the background with the same result', () async {
      expect(
        await hashInBackground('c2FsdHNhbHRzYWx0c2FsdA', 'correct horse'),
        'upHRdgO/QHkziDqCg2ImqCU0fU/xCI77gk3FYuCn7WM=',
      );
    });
  });

  test('newSalt is random and url-safe', () {
    final a = newSalt();
    final b = newSalt();
    expect(a, isNot(b));
    expect(a, matches(RegExp(r'^[A-Za-z0-9_=-]+$')));
  });

  test('constantTimeEquals compares whole strings', () {
    expect(constantTimeEquals('abc', 'abc'), isTrue);
    expect(constantTimeEquals('abc', 'abd'), isFalse);
    expect(constantTimeEquals('abc', 'abcd'), isFalse);
  });
}
