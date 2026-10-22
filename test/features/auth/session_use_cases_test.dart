import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/core/storage/secure_storage.dart';
import 'package:fusion/features/app_lock/data/datasources/app_lock_local_data_source.dart';
import 'package:fusion/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:fusion/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:fusion/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fusion/features/auth/domain/usecases/erase_everything.dart';
import 'package:fusion/features/auth/domain/usecases/lock_vault.dart';
import 'package:fusion/features/auth/domain/usecases/log_in_with_password.dart';
import 'package:fusion/features/auth/domain/usecases/sign_up.dart';
import 'package:fusion/features/auth/domain/usecases/unlock_with_app_lock.dart';
import 'package:fusion/features/auth/domain/usecases/use_master_password_instead.dart';
import 'package:fusion/features/app_lock/domain/usecases/should_lock_on_hide.dart';
import 'package:fusion/features/vault/data/datasources/vault_local_data_source.dart';
import 'package:fusion/features/vault/data/repositories/vault_repository_impl.dart';

import '../../fakes.dart';

class _Env {
  _Env(this.auth, this.lock, this.vault);

  final AuthRepositoryImpl auth;
  final AppLockRepositoryImpl lock;
  final VaultRepositoryImpl vault;

  /// (loggedIn, hasAccount, hasPin, masterPasswordRequested) at every change.
  final routes = <(bool, bool, bool, bool)>[];

  void watch() {
    void note() => routes.add((
      auth.current.loggedIn,
      auth.current.hasAccount,
      lock.current.hasPin,
      lock.current.masterPasswordRequested,
    ));
    auth.changes.listen((_) => note());
    lock.changes.listen((_) => note());
  }
}

Future<_Env> _env() async {
  final auth = AuthRepositoryImpl(
    const SecureAuthLocalDataSource(fusionStorage),
    hasher: fastHash,
  );
  final lock = AppLockRepositoryImpl(
    const SecureAppLockLocalDataSource(fusionStorage),
    biometrics: FakeBiometricAuth(),
    hasher: fastHash,
  );
  final vault = VaultRepositoryImpl(
    const SecureVaultLocalDataSource(fusionStorage),
  );
  await auth.init();
  await lock.init();
  return _Env(auth, lock, vault);
}

Future<_Env> _withPin() async {
  final e = await _env();
  await SignUp(e.auth, e.lock)(
    const SignUpParams(name: 'Ada', email: 'ada@x.io', password: 'pw'),
  );
  await e.lock.setPin('123456');
  await e.vault.load();
  return e;
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('a master password login clears PIN strikes and the fallback', () async {
    final e = await _withPin();
    e.auth.logOut();
    for (var i = 0; i < 5; i++) {
      await e.lock.verifyPin('000000');
    }
    e.lock.requestMasterPassword();
    expect(e.lock.current.pinLockedOut, isTrue);

    final r = await LogInWithPassword(e.auth, e.lock)(
      const LogInParams(email: 'ada@x.io', password: 'pw'),
    );
    expect(r.isOk, isTrue);
    expect(e.lock.current.pinLockedOut, isFalse);
    expect(e.lock.current.masterPasswordRequested, isFalse);
  });

  test('a failed login keeps the fallback (the login stays up)', () async {
    final e = await _withPin();
    e.auth.logOut();
    e.lock.requestMasterPassword();
    await LogInWithPassword(e.auth, e.lock)(
      const LogInParams(email: 'ada@x.io', password: 'wrong'),
    );
    expect(e.lock.current.masterPasswordRequested, isTrue);
  });

  test('unlocking with the app lock opens the vault', () async {
    final e = await _withPin();
    e.auth.logOut();
    await e.lock.verifyPin('000000');
    await UnlockWithAppLock(e.auth, e.lock)();
    expect(e.auth.current.loggedIn, isTrue);
    expect(e.lock.current.failed, 0);
  });

  test('Lock vault forgets the vault and skips the next prompt', () async {
    final e = await _withPin();
    LockVault(e.auth, e.lock, e.vault)();
    expect(e.auth.current.loggedIn, isFalse);
    expect(e.vault.current.loaded, isFalse);
    expect(e.lock.consumeSkipAutoPrompt(), isTrue);
  });

  test(
    'the master password fallback never passes through the PIN lock',
    () async {
      final e = await _withPin();
      e.watch();
      UseMasterPasswordInstead(e.auth, e.lock, e.vault)();
      await _flush();
      expect(e.auth.current.loggedIn, isFalse);
      expect(e.vault.current.loaded, isFalse);
      // Logged out with a PIN but no fallback would mean "show the PIN lock".
      expect(e.routes, isNot(contains((false, true, true, false))));
      expect(e.routes.last, (false, true, true, true));
    },
  );

  test('erasing forgets the PIN and never shows PIN setup', () async {
    final e = await _withPin();
    await e.lock.setBiometric(true);
    e.watch();
    await EraseEverything(e.auth, e.lock, e.vault)();
    await _flush();
    expect(e.auth.current.hasAccount, isFalse);
    expect(e.lock.current.hasPin, isFalse);
    expect(e.lock.current.biometricEnabled, isFalse);
    expect(e.vault.current.items, isEmpty);
    expect(await fusionStorage.readAll(), isEmpty);
    // Logged in without a PIN would mean "show PIN setup".
    expect(e.routes, isNot(contains((true, true, false, false))));
  });

  test('only an open vault with a PIN locks on hide', () async {
    final e = await _env();
    final should = ShouldLockOnHide(e.auth, e.lock);
    expect(should(), isFalse);
    await SignUp(e.auth, e.lock)(
      const SignUpParams(name: 'Ada', email: 'ada@x.io', password: 'pw'),
    );
    expect(should(), isFalse);
    await e.lock.setPin('123456');
    expect(should(), isTrue);
    e.auth.logOut();
    expect(should(), isFalse);
  });
}
