import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/core/security/hashing.dart';
import 'package:fusion/core/storage/secure_storage.dart';
import 'package:fusion/features/app_lock/data/datasources/app_lock_local_data_source.dart';
import 'package:fusion/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:fusion/features/app_lock/domain/entities/biometric_kind.dart';

import '../../fakes.dart';

Future<AppLockRepositoryImpl> _lock({
  FakeBiometricAuth? bio,
  PasswordHasher hasher = fastHash,
}) async {
  final c = AppLockRepositoryImpl(
    const SecureAppLockLocalDataSource(fusionStorage),
    biometrics: bio ?? FakeBiometricAuth(),
    hasher: hasher,
  );
  await c.init();
  return c;
}

Future<Map<String, dynamic>> _stored() async =>
    jsonDecode((await fusionStorage.read(key: StorageKeys.appLock))!)
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('PIN', () {
    test('starts without a PIN', () async {
      final lock = await _lock();
      expect(lock.current.ready, isTrue);
      expect(lock.current.hasPin, isFalse);
      expect(lock.current.pinLockedOut, isFalse);
    });

    test('verifies the PIN that was set, across instances', () async {
      final lock = await _lock();
      await lock.setPin('123456');
      expect(lock.current.hasPin, isTrue);

      final fresh = await _lock();
      expect(fresh.current.hasPin, isTrue);
      expect(await fresh.verifyPin('123456'), isTrue);
      expect(await fresh.verifyPin('654321'), isFalse);
    });

    test('never stores the PIN itself', () async {
      final lock = await _lock();
      await lock.setPin('123456');
      final m = await _stored();
      expect(m['hash'], isNot('123456'));
      expect(m.containsKey('pin'), isFalse);
      expect(m.keys, containsAll(['salt', 'hash', 'biometric', 'failed']));
    });

    test('rejects a PIN that is not 6 digits', () async {
      final lock = await _lock();
      expect(() => lock.setPin('12345'), throwsArgumentError);
      expect(() => lock.setPin('12345a'), throwsArgumentError);
    });

    test('works with the real stretched hash', () async {
      final lock = await _lock(hasher: hashInBackground);
      await lock.setPin('246810');
      expect((await _stored())['hash'], hasLength(44));
      expect(await lock.verifyPin('246810'), isTrue);
    });

    test('a hash without its salt counts as no PIN', () async {
      FlutterSecureStorage.setMockInitialValues({
        StorageKeys.appLock: jsonEncode({'hash': 'x'}),
      });
      expect((await _lock()).current.hasPin, isFalse);
    });

    test('unreadable storage counts as no PIN', () async {
      FlutterSecureStorage.setMockInitialValues({StorageKeys.appLock: '{'});
      final lock = await _lock();
      expect(lock.current.ready, isTrue);
      expect(lock.current.hasPin, isFalse);
    });
  });

  group('wrong attempts', () {
    test('count down and lock the PIN out after 5', () async {
      final lock = await _lock();
      await lock.setPin('123456');
      for (var i = 0; i < 4; i++) {
        expect(await lock.verifyPin('000000'), isFalse);
      }
      expect(lock.current.attemptsLeft, 1);
      expect(lock.current.pinLockedOut, isFalse);
      expect(await lock.verifyPin('000000'), isFalse);
      expect(lock.current.pinLockedOut, isTrue);
      // Even the right PIN is refused once locked out.
      expect(await lock.verifyPin('123456'), isFalse);
    });

    test('survive an app restart', () async {
      final lock = await _lock();
      await lock.setPin('123456');
      await lock.verifyPin('000000');
      await lock.verifyPin('000000');
      expect((await _lock()).current.failed, 2);
    });

    test('reset after a correct PIN', () async {
      final lock = await _lock();
      await lock.setPin('123456');
      await lock.verifyPin('000000');
      expect(await lock.verifyPin('123456'), isTrue);
      expect(lock.current.failed, 0);
    });

    test('clearAfterUnlock clears strikes and the fallback', () async {
      final lock = await _lock();
      await lock.setPin('123456');
      for (var i = 0; i < 5; i++) {
        await lock.verifyPin('000000');
      }
      lock.requestMasterPassword();
      await lock.clearAfterUnlock();
      expect(lock.current.pinLockedOut, isFalse);
      expect(lock.current.masterPasswordRequested, isFalse);
      expect((await _lock()).current.failed, 0);
    });

    test(
      'clearAfterUnlock writes nothing when there were no strikes',
      () async {
        final lock = await _lock();
        await lock.clearAfterUnlock();
        expect(await fusionStorage.read(key: StorageKeys.appLock), isNull);
      },
    );
  });

  group('biometrics', () {
    test('reports what the device offers', () async {
      final lock = await _lock(
        bio: FakeBiometricAuth(kind: BiometricKind.fingerprint),
      );
      expect(lock.current.kind, BiometricKind.fingerprint);
      expect(lock.current.biometricEnabled, isFalse);
    });

    test('the on/off choice persists', () async {
      final lock = await _lock();
      await lock.setPin('123456');
      await lock.setBiometric(true);
      expect((await _lock()).current.biometricEnabled, isTrue);
    });

    test('canUseBiometric needs both the setting and the hardware', () async {
      final lock = await _lock(
        bio: FakeBiometricAuth(kind: BiometricKind.none),
      );
      await lock.setPin('123456');
      await lock.setBiometric(true);
      expect(lock.current.canUseBiometric, isFalse);
    });

    test('tryBiometric prompts and reports success', () async {
      final bio = FakeBiometricAuth();
      final lock = await _lock(bio: bio);
      await lock.setPin('123456');
      await lock.setBiometric(true);
      expect(await lock.tryBiometric('Unlock'), isTrue);
      expect(bio.prompts, 1);
    });

    test('tryBiometric is refused while the PIN is locked out', () async {
      final bio = FakeBiometricAuth();
      final lock = await _lock(bio: bio);
      await lock.setPin('123456');
      await lock.setBiometric(true);
      for (var i = 0; i < 5; i++) {
        await lock.verifyPin('000000');
      }
      expect(await lock.tryBiometric('Unlock'), isFalse);
      expect(bio.prompts, 0);
    });

    test('refreshBiometrics picks up newly enrolled hardware', () async {
      final bio = FakeBiometricAuth(kind: BiometricKind.none);
      final lock = await _lock(bio: bio);
      bio.kind = BiometricKind.face;
      await lock.refreshBiometrics();
      expect(lock.current.kind, BiometricKind.face);
    });
  });

  test('the automatic prompt is skipped exactly once', () async {
    final lock = await _lock();
    lock.skipNextAutoPrompt();
    expect(lock.consumeSkipAutoPrompt(), isTrue);
    expect(lock.consumeSkipAutoPrompt(), isFalse);
  });

  test('master password fallback: request and cancel', () async {
    final lock = await _lock();
    lock.requestMasterPassword();
    expect(lock.current.masterPasswordRequested, isTrue);
    lock.cancelMasterPassword();
    expect(lock.current.masterPasswordRequested, isFalse);
  });

  test('forget drops the PIN from memory without writing', () async {
    final lock = await _lock();
    await lock.setPin('123456');
    await lock.setBiometric(true);
    await fusionStorage.deleteAll();
    lock.forget();
    expect(lock.current.hasPin, isFalse);
    expect(lock.current.biometricEnabled, isFalse);
    expect(await fusionStorage.readAll(), isEmpty);
  });
}
