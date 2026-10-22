import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/core/error/failures.dart';
import 'package:fusion/core/error/result.dart';
import 'package:fusion/core/security/hashing.dart';
import 'package:fusion/core/storage/secure_storage.dart';
import 'package:fusion/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:fusion/features/auth/data/repositories/auth_repository_impl.dart';

import '../../fakes.dart';

Future<AuthRepositoryImpl> _auth({
  PasswordHasher hasher = fastHash,
  DateTime Function()? clock,
}) async {
  final auth = AuthRepositoryImpl(
    const SecureAuthLocalDataSource(fusionStorage),
    hasher: hasher,
    clock: clock,
  );
  await auth.init();
  return auth;
}

Future<AuthRepositoryImpl> _signedUp() async {
  final auth = await _auth();
  await auth.signUp(name: 'Ada Lovelace', email: 'Ada@X.io ', password: 'pw');
  return auth;
}

AuthField? _field(Result<Object?> r) => switch (r.failureOrNull) {
  AuthFailure(:final field) => field,
  _ => null,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('a fresh device is ready with no account', () async {
    final auth = await _auth();
    expect(auth.current.ready, isTrue);
    expect(auth.current.hasAccount, isFalse);
    expect(auth.current.loggedIn, isFalse);
  });

  test('unreadable storage counts as a fresh device', () async {
    FlutterSecureStorage.setMockInitialValues({StorageKeys.account: '{nope'});
    final auth = await _auth();
    expect(auth.current.ready, isTrue);
    expect(auth.current.hasAccount, isFalse);
  });

  test('signing up stores a normalised account and opens the vault', () async {
    final auth = await _signedUp();
    expect(auth.current.loggedIn, isTrue);
    expect(auth.current.account?.email, 'ada@x.io');
    expect(auth.current.firstName, 'Ada');

    final raw = await fusionStorage.read(key: StorageKeys.account);
    final m = jsonDecode(raw!) as Map<String, dynamic>;
    expect(m.keys, containsAll(['name', 'email', 'salt', 'hash']));
    expect(m['hash'], isNot('pw'));
  });

  test('a second sign-up is refused', () async {
    final auth = await _signedUp();
    final r = await auth.signUp(name: 'B', email: 'b@x.io', password: 'pw');
    expect(_field(r), AuthField.email);
  });

  group('logIn', () {
    test('needs an account', () async {
      final auth = await _auth();
      expect(_field(await auth.logIn('ada@x.io', 'pw')), AuthField.email);
    });

    test('checks the email, then the password', () async {
      final auth = await _signedUp();
      auth.logOut();
      expect(_field(await auth.logIn('bob@x.io', 'pw')), AuthField.email);
      expect(_field(await auth.logIn('ada@x.io', 'no')), AuthField.password);
      expect(auth.current.loggedIn, isFalse);
      expect((await auth.logIn(' ADA@x.io', 'pw')).isOk, isTrue);
      expect(auth.current.loggedIn, isTrue);
    });

    test('a failing hasher becomes a password error', () async {
      final auth = await _signedUp();
      auth.logOut();
      final broken = AuthRepositoryImpl(
        const SecureAuthLocalDataSource(fusionStorage),
        hasher: (_, __) async => throw StateError('isolate died'),
      );
      await broken.init();
      final r = await broken.logIn('ada@x.io', 'pw');
      expect(_field(r), AuthField.password);
    });

    test('existing accounts made with the real hash still log in', () async {
      final auth = await _auth(hasher: hashInBackground);
      await auth.signUp(name: 'Ada', email: 'ada@x.io', password: 'pw');
      auth.logOut();
      final fresh = await _auth(hasher: hashInBackground);
      expect((await fresh.logIn('ada@x.io', 'nope')).isOk, isFalse);
      expect((await fresh.logIn('ada@x.io', 'pw')).isOk, isTrue);
    });
  });

  group('unlock', () {
    test('opens the vault for an existing account', () async {
      final auth = await _signedUp();
      auth.logOut();
      auth.unlock();
      expect(auth.current.loggedIn, isTrue);
    });

    test('does nothing without an account', () async {
      final auth = await _auth();
      auth.unlock();
      expect(auth.current.loggedIn, isFalse);
    });
  });

  group('passwordVerified', () {
    test('is set by a master password login or signup', () async {
      final auth = await _signedUp();
      expect(auth.current.passwordVerified, isTrue);
      auth.logOut();
      expect(auth.current.passwordVerified, isFalse);
      await auth.logIn('ada@x.io', 'pw');
      expect(auth.current.passwordVerified, isTrue);
    });

    test('is not set by the app lock', () async {
      final auth = await _signedUp();
      auth.logOut();
      auth.unlock();
      expect(auth.current.loggedIn, isTrue);
      expect(auth.current.passwordVerified, isFalse);
    });
  });

  group('password reset', () {
    test('needs an account and its email', () async {
      expect((await _auth()).requestReset('ada@x.io').isOk, isFalse);
      final auth = await _signedUp();
      expect(auth.requestReset('bob@x.io').isOk, isFalse);
    });

    test('the code sets a new password', () async {
      final auth = await _signedUp();
      auth.logOut();
      final code = (auth.requestReset(' ada@x.io') as Ok<String>).value;
      expect(code, matches(RegExp(r'^\d{6}$')));
      expect(auth.pendingResetEmail, 'ada@x.io');

      final wrong = code == '000000' ? '111111' : '000000';
      expect(_field(await auth.resetPassword(wrong, 'new')), AuthField.code);
      expect((await auth.resetPassword(code, 'new')).isOk, isTrue);
      expect((await auth.logIn('ada@x.io', 'pw')).isOk, isFalse);
      expect((await auth.logIn('ada@x.io', 'new')).isOk, isTrue);
    });

    test('a code is used once', () async {
      final auth = await _signedUp();
      final code = (auth.requestReset('ada@x.io') as Ok<String>).value;
      await auth.resetPassword(code, 'new');
      expect(_field(await auth.resetPassword(code, 'other')), AuthField.code);
    });

    test('codes expire after 10 minutes', () async {
      var now = DateTime(2026, 1, 1, 12);
      final auth = await _auth(clock: () => now);
      await auth.signUp(name: 'Ada', email: 'ada@x.io', password: 'pw');
      final code = (auth.requestReset('ada@x.io') as Ok<String>).value;
      now = now.add(const Duration(minutes: 11));
      final r = await auth.resetPassword(code, 'new');
      expect(r.failureOrNull?.message, contains('expired'));
    });
  });

  test('wipe erases every stored key and logs out', () async {
    FlutterSecureStorage.setMockInitialValues({StorageKeys.vault: '[]'});
    final auth = await _signedUp();
    await auth.wipe();
    expect(auth.current.hasAccount, isFalse);
    expect(auth.current.loggedIn, isFalse);
    expect(await fusionStorage.readAll(), isEmpty);
  });

  test('changes are announced once per change', () async {
    final auth = await _auth();
    final seen = <bool>[];
    auth.changes.listen((s) => seen.add(s.loggedIn));
    await auth.signUp(name: 'Ada', email: 'ada@x.io', password: 'pw');
    auth.logOut();
    auth.logOut();
    await Future<void>.delayed(Duration.zero);
    expect(seen, [true, false]);
  });
}
