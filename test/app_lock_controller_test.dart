import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/services/app_lock_controller.dart';
import 'package:fusion/services/auth_service.dart';
import 'package:fusion/services/biometric_auth.dart';

import 'fakes.dart';

const _storage = FlutterSecureStorage();

Future<AuthService> _auth() async {
  final auth = AuthService();
  await auth.init();
  return auth;
}

Future<AppLockController> _lock(
  AuthService auth, {
  FakeBiometricAuth? bio,
}) async {
  final c = AppLockController(
    auth: auth,
    biometrics: bio ?? FakeBiometricAuth(),
    hasher: fastHash,
  );
  await c.init();
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('PIN', () {
    test('starts without a PIN', () async {
      final lock = await _lock(await _auth());
      expect(lock.hasPin, isFalse);
      expect(lock.pinLockedOut, isFalse);
    });

    test('verifies the PIN that was set, across instances', () async {
      final auth = await _auth();
      final lock = await _lock(auth);
      await lock.setPin('123456');
      expect(lock.hasPin, isTrue);

      final fresh = await _lock(auth);
      expect(fresh.hasPin, isTrue);
      expect(await fresh.verifyPin('123456'), isTrue);
      expect(await fresh.verifyPin('654321'), isFalse);
    });

    test('never stores the PIN itself', () async {
      final lock = await _lock(await _auth());
      await lock.setPin('123456');
      final raw = await _storage.read(key: 'fusion.applock.v1');
      final m = jsonDecode(raw!) as Map<String, dynamic>;
      expect(m['hash'], isNot('123456'));
      expect(m.containsKey('pin'), isFalse);
    });

    test('rejects a PIN that is not 6 digits', () async {
      final lock = await _lock(await _auth());
      expect(() => lock.setPin('12345'), throwsArgumentError);
      expect(() => lock.setPin('12345a'), throwsArgumentError);
    });

    test('uses the real stretched hash by default', () async {
      final auth = await _auth();
      final lock = AppLockController(
        auth: auth,
        biometrics: FakeBiometricAuth(),
      );
      await lock.init();
      await lock.setPin('246810');
      final raw = await _storage.read(key: 'fusion.applock.v1');
      final m = jsonDecode(raw!) as Map<String, dynamic>;
      expect(m['hash'], hasLength(44)); // base64 of a SHA-256 digest
      expect(await lock.verifyPin('246810'), isTrue);
    });
  });

  group('wrong attempts', () {
    test('counts down and locks the PIN out after 5', () async {
      final lock = await _lock(await _auth());
      await lock.setPin('123456');
      for (var i = 0; i < 4; i++) {
        expect(await lock.verifyPin('000000'), isFalse);
      }
      expect(lock.attemptsLeft, 1);
      expect(lock.pinLockedOut, isFalse);
      expect(await lock.verifyPin('000000'), isFalse);
      expect(lock.pinLockedOut, isTrue);
      // Even the right PIN is refused once locked out.
      expect(await lock.verifyPin('123456'), isFalse);
    });

    test('survive an app restart', () async {
      final auth = await _auth();
      final lock = await _lock(auth);
      await lock.setPin('123456');
      await lock.verifyPin('000000');
      await lock.verifyPin('000000');

      final fresh = await _lock(auth);
      expect(fresh.failedAttempts, 2);
    });

    test('reset after a correct PIN', () async {
      final lock = await _lock(await _auth());
      await lock.setPin('123456');
      await lock.verifyPin('000000');
      expect(await lock.verifyPin('123456'), isTrue);
      expect(lock.failedAttempts, 0);
    });

    test('reset when the user logs in with the master password', () async {
      final auth = await _auth();
      await auth.signUp(name: 'Ada', email: 'ada@x.io', password: 'pw');
      auth.logout();
      final lock = await _lock(auth);
      await lock.setPin('123456');
      for (var i = 0; i < 5; i++) {
        await lock.verifyPin('000000');
      }
      lock.requestMasterPassword();
      expect(lock.pinLockedOut, isTrue);

      expect(await auth.login('ada@x.io', 'pw'), isNull);
      expect(lock.pinLockedOut, isFalse);
      expect(lock.masterPasswordRequested, isFalse);
      expect((await _lock(auth)).failedAttempts, 0);
    });
  });

  group('biometrics', () {
    test('reports what the device offers', () async {
      final lock = await _lock(
        await _auth(),
        bio: FakeBiometricAuth(kind: BiometricKind.fingerprint),
      );
      expect(lock.biometricKind, BiometricKind.fingerprint);
      expect(lock.biometricEnabled, isFalse);
    });

    test('the on/off choice persists', () async {
      final auth = await _auth();
      final lock = await _lock(auth);
      await lock.setPin('123456');
      await lock.setBiometric(true);
      expect((await _lock(auth)).biometricEnabled, isTrue);
    });

    test('canUseBiometric needs both the setting and the hardware', () async {
      final auth = await _auth();
      final bio = FakeBiometricAuth(kind: BiometricKind.none);
      final lock = await _lock(auth, bio: bio);
      await lock.setPin('123456');
      await lock.setBiometric(true);
      expect(lock.canUseBiometric, isFalse);
    });

    test('tryBiometric prompts and reports success', () async {
      final bio = FakeBiometricAuth();
      final lock = await _lock(await _auth(), bio: bio);
      await lock.setPin('123456');
      await lock.setBiometric(true);
      expect(await lock.tryBiometric('Unlock'), isTrue);
      expect(bio.prompts, 1);
    });

    test('tryBiometric is refused while the PIN is locked out', () async {
      final bio = FakeBiometricAuth();
      final lock = await _lock(await _auth(), bio: bio);
      await lock.setPin('123456');
      await lock.setBiometric(true);
      for (var i = 0; i < 5; i++) {
        await lock.verifyPin('000000');
      }
      expect(await lock.tryBiometric('Unlock'), isFalse);
      expect(bio.prompts, 0);
    });
  });

  group('master password fallback', () {
    test('request and cancel', () async {
      final lock = await _lock(await _auth());
      lock.requestMasterPassword();
      expect(lock.masterPasswordRequested, isTrue);
      lock.cancelMasterPassword();
      expect(lock.masterPasswordRequested, isFalse);
    });
  });

  test('forgets everything when the vault is erased', () async {
    final auth = await _auth();
    await auth.signUp(name: 'Ada', email: 'ada@x.io', password: 'pw');
    final lock = await _lock(auth);
    await lock.setPin('123456');
    await lock.setBiometric(true);

    await auth.wipe();
    expect(lock.hasPin, isFalse);
    expect(lock.biometricEnabled, isFalse);
  });
}
