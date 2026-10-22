import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/app/di/injection.dart';
import 'package:fusion/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:fusion/features/auth/domain/repositories/auth_repository.dart';
import 'package:fusion/features/settings/domain/entities/app_theme_mode.dart';
import 'package:fusion/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:fusion/features/settings/presentation/cubit/theme_cubit.dart';

import '../../fakes.dart';
import '../../helpers/di.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('turning biometrics on asks first', () async {
    final bio = await setUpDi(loggedIn: true);
    await sl<SettingsCubit>().setBiometric(true, 'Face ID');
    expect(bio.prompts, 1);
    expect(sl<AppLockRepository>().current.biometricEnabled, isTrue);
  });

  test('a failed check leaves biometrics off and says so', () async {
    await setUpDi(loggedIn: true, bio: FakeBiometricAuth(result: false));
    final cubit = sl<SettingsCubit>();
    final effects = <SettingsEffect>[];
    cubit.effects.listen(effects.add);
    await cubit.setBiometric(true, 'Face ID');
    await flush();
    expect(sl<AppLockRepository>().current.biometricEnabled, isFalse);
    expect((effects.single as BiometricNotVerified).label, 'Face ID');
  });

  test('turning biometrics off needs no prompt', () async {
    final bio = await setUpDi(loggedIn: true, biometric: true);
    await sl<SettingsCubit>().setBiometric(false, 'Face ID');
    expect(bio.prompts, 0);
    expect(sl<AppLockRepository>().current.biometricEnabled, isFalse);
  });

  test('Lock vault logs out and skips the next prompt once', () async {
    await setUpDi(loggedIn: true);
    sl<SettingsCubit>().lockVault();
    expect(sl<AuthRepository>().current.loggedIn, isFalse);
    expect(sl<AppLockRepository>().consumeSkipAutoPrompt(), isTrue);
    expect(sl<AppLockRepository>().consumeSkipAutoPrompt(), isFalse);
  });

  test('erasing removes the account', () async {
    await setUpDi(loggedIn: true);
    await sl<SettingsCubit>().eraseEverything();
    expect(sl<AuthRepository>().current.hasAccount, isFalse);
  });

  test('the theme choice persists', () async {
    await setUpDi();
    await sl<ThemeCubit>().select(AppThemeMode.dark);
    await sl.reset();
    configureDependencies(biometrics: FakeBiometricAuth(), hasher: fastHash);
    final fresh = sl<ThemeCubit>();
    await fresh.load();
    expect(fresh.state, AppThemeMode.dark);
  });
}
