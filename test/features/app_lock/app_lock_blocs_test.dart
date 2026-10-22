import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/app/di/injection.dart';
import 'package:fusion/features/app_lock/domain/entities/biometric_kind.dart';
import 'package:fusion/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:fusion/features/app_lock/presentation/bloc/app_lock_bloc.dart';
import 'package:fusion/features/app_lock/presentation/cubits/app_lock_setup_cubit.dart';
import 'package:fusion/features/app_lock/presentation/cubits/lock_cubit.dart';
import 'package:fusion/features/auth/domain/repositories/auth_repository.dart';

import '../../fakes.dart';
import '../../helpers/di.dart';

Future<void> _type(void Function(String) digit, String pin) async {
  for (final d in pin.split('')) {
    digit(d);
  }
  await flush();
  await flush();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLockBloc', () {
    test('locks on hide only with an open vault and a PIN', () async {
      await setUpDi();
      final bloc = sl<AppLockBloc>()..add(const AppHidden());
      await flush();
      expect(bloc.state.resumeLocked, isFalse);

      sl<AuthRepository>().unlock();
      bloc.add(const AppHidden());
      await flush();
      expect(bloc.state.resumeLocked, isTrue);

      bloc.add(const ResumeUnlocked());
      await flush();
      expect(bloc.state.resumeLocked, isFalse);
    });

    test('no lock during PIN setup', () async {
      await setUpDi(pin: false, loggedIn: true);
      final bloc = sl<AppLockBloc>()..add(const AppHidden());
      await flush();
      expect(bloc.state.resumeLocked, isFalse);
    });

    test('logging out drops the resume lock', () async {
      await setUpDi(loggedIn: true);
      final bloc = sl<AppLockBloc>()..add(const AppHidden());
      await flush();
      sl<AuthRepository>().logOut();
      await flush();
      await flush();
      expect(bloc.state.resumeLocked, isFalse);
    });
  });

  group('LockCubit', () {
    test('the right PIN opens the vault on launch', () async {
      await setUpDi();
      final cubit = sl<LockCubit>(param1: false);
      await _type(cubit.digit, '123456');
      expect(sl<AuthRepository>().current.loggedIn, isTrue);
      expect(cubit.state.done, isTrue);
    });

    test('a wrong PIN says how many tries are left and resets', () async {
      await setUpDi();
      final cubit = sl<LockCubit>(param1: false);
      final effects = <LockEffect>[];
      cubit.effects.listen(effects.add);
      await _type(cubit.digit, '111111');
      expect(cubit.state.error, 'Wrong PIN · 4 tries left');
      expect(cubit.state.entered, '');
      expect(effects, [LockEffect.wrongPin]);
    });

    test('the fifth wrong PIN locks it out', () async {
      await setUpDi(failed: 4);
      final cubit = sl<LockCubit>(param1: false);
      await _type(cubit.digit, '111111');
      expect(cubit.state.error, lockedOutMessage);
      expect(sl<AppLockRepository>().current.pinLockedOut, isTrue);
    });

    test('opens already locked out after a restart', () async {
      await setUpDi(failed: 5);
      expect(sl<LockCubit>(param1: false).state.error, lockedOutMessage);
    });

    test('on resume it only reports the unlock', () async {
      await setUpDi(loggedIn: true);
      final cubit = sl<LockCubit>(param1: true);
      final effects = <LockEffect>[];
      cubit.effects.listen(effects.add);
      await _type(cubit.digit, '123456');
      expect(effects, [LockEffect.resumeUnlocked]);
    });

    test('biometrics unlock once; the PIN is then ignored', () async {
      final bio = await setUpDi(biometric: true);
      final cubit = sl<LockCubit>(param1: false);
      expect(cubit.shouldAutoPrompt(), isTrue);
      await cubit.biometric();
      expect(bio.prompts, 1);
      expect(sl<AuthRepository>().current.loggedIn, isTrue);
      cubit.digit('1');
      expect(cubit.state.entered, '');
    });

    test('no automatic prompt right after Lock vault, once', () async {
      await setUpDi(biometric: true);
      sl<AppLockRepository>().skipNextAutoPrompt();
      expect(sl<LockCubit>(param1: false).shouldAutoPrompt(), isFalse);
      expect(sl<LockCubit>(param1: false).shouldAutoPrompt(), isTrue);
    });

    test('no automatic prompt with biometrics off', () async {
      await setUpDi();
      expect(sl<LockCubit>(param1: false).shouldAutoPrompt(), isFalse);
    });

    test('the master password fallback logs out from a resume lock', () async {
      await setUpDi(loggedIn: true);
      sl<LockCubit>(param1: true).useMasterPassword();
      expect(sl<AuthRepository>().current.loggedIn, isFalse);
      expect(sl<AppLockRepository>().current.masterPasswordRequested, isTrue);
    });
  });

  group('AppLockSetupCubit', () {
    test('create and confirm saves the PIN', () async {
      await setUpDi(
        pin: false,
        loggedIn: true,
        bio: FakeBiometricAuth(kind: BiometricKind.none),
      );
      final cubit = sl<AppLockSetupCubit>(param1: false);
      expect(cubit.state.step, SetupStep.create);
      await _type(cubit.digit, '135790');
      expect(cubit.state.step, SetupStep.confirm);
      expect(sl<AppLockRepository>().current.hasPin, isFalse);
      await _type(cubit.digit, '135790');
      expect(sl<AppLockRepository>().current.hasPin, isTrue);
      expect(cubit.state.busy, isTrue); // until the app moves on
    });

    test('a mismatch starts over', () async {
      await setUpDi(pin: false, loggedIn: true);
      final cubit = sl<AppLockSetupCubit>(param1: false);
      await _type(cubit.digit, '135790');
      await _type(cubit.digit, '135791');
      expect(cubit.state.step, SetupStep.create);
      expect(cubit.state.error, 'PINs didn’t match. Try again.');
    });

    test('offers biometrics before saving, and saves both', () async {
      final bio = await setUpDi(
        pin: false,
        loggedIn: true,
        bio: FakeBiometricAuth(kind: BiometricKind.face),
      );
      final cubit = sl<AppLockSetupCubit>(param1: false);
      await _type(cubit.digit, '135790');
      await _type(cubit.digit, '135790');
      expect(cubit.state.step, SetupStep.biometric);
      expect(sl<AppLockRepository>().current.hasPin, isFalse);
      await cubit.enableBiometric('Face ID');
      expect(bio.prompts, 1);
      expect(sl<AppLockRepository>().current.hasPin, isTrue);
      expect(sl<AppLockRepository>().current.biometricEnabled, isTrue);
    });

    test('a failed biometric check keeps the choice open', () async {
      await setUpDi(
        pin: false,
        loggedIn: true,
        bio: FakeBiometricAuth(kind: BiometricKind.face, result: false),
      );
      final cubit = sl<AppLockSetupCubit>(param1: false);
      await _type(cubit.digit, '135790');
      await _type(cubit.digit, '135790');
      await cubit.enableBiometric('Face ID');
      expect(cubit.state.error, 'Couldn’t verify Face ID. Try again.');
      expect(sl<AppLockRepository>().current.hasPin, isFalse);
    });

    test('changing asks for the current PIN after a PIN unlock', () async {
      await setUpDi(loggedIn: true);
      final cubit = sl<AppLockSetupCubit>(param1: true);
      expect(cubit.state.step, SetupStep.current);
      await _type(cubit.digit, '000000');
      expect(cubit.state.error, 'Wrong PIN · 4 tries left');
      expect(sl<AppLockRepository>().current.failed, 1);
    });

    test('changing replaces the PIN and says so', () async {
      await setUpDi(loggedIn: true);
      final cubit = sl<AppLockSetupCubit>(param1: true);
      final effects = <AppLockSetupEffect>[];
      cubit.effects.listen(effects.add);
      await _type(cubit.digit, '123456');
      await _type(cubit.digit, '246802');
      await _type(cubit.digit, '246802');
      expect(effects, [AppLockSetupEffect.changed]);
      expect(await sl<AppLockRepository>().verifyPin('246802'), isTrue);
    });
  });
}
