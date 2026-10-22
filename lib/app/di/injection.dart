import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../core/network/dio_client.dart';
import '../../core/router/draft_password.dart';
import '../../core/security/hashing.dart';
import '../../core/storage/secure_storage.dart';
import '../../features/app_lock/data/datasources/app_lock_local_data_source.dart';
import '../../features/app_lock/data/datasources/biometric_data_source.dart';
import '../../features/app_lock/data/repositories/app_lock_repository_impl.dart';
import '../../features/app_lock/domain/repositories/app_lock_repository.dart';
import '../../features/app_lock/domain/usecases/cancel_master_password.dart';
import '../../features/app_lock/domain/usecases/confirm_biometric.dart';
import '../../features/app_lock/domain/usecases/consume_skip_auto_prompt.dart';
import '../../features/app_lock/domain/usecases/get_app_lock_status.dart';
import '../../features/app_lock/domain/usecases/init_app_lock.dart';
import '../../features/app_lock/domain/usecases/refresh_biometrics.dart';
import '../../features/app_lock/domain/usecases/set_biometric.dart';
import '../../features/app_lock/domain/usecases/set_pin.dart';
import '../../features/app_lock/domain/usecases/should_lock_on_hide.dart';
import '../../features/app_lock/domain/usecases/try_biometric.dart';
import '../../features/app_lock/domain/usecases/verify_pin.dart';
import '../../features/app_lock/domain/usecases/watch_app_lock_status.dart';
import '../../features/app_lock/presentation/bloc/app_lock_bloc.dart';
import '../../features/app_lock/presentation/cubits/app_lock_setup_cubit.dart';
import '../../features/app_lock/presentation/cubits/lock_cubit.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/erase_everything.dart';
import '../../features/auth/domain/usecases/get_auth_session.dart';
import '../../features/auth/domain/usecases/get_pending_reset_email.dart';
import '../../features/auth/domain/usecases/init_auth.dart';
import '../../features/auth/domain/usecases/lock_vault.dart';
import '../../features/auth/domain/usecases/log_in_with_password.dart';
import '../../features/auth/domain/usecases/request_password_reset.dart';
import '../../features/auth/domain/usecases/reset_password.dart';
import '../../features/auth/domain/usecases/sign_up.dart';
import '../../features/auth/domain/usecases/unlock_with_app_lock.dart';
import '../../features/auth/domain/usecases/use_master_password_instead.dart';
import '../../features/auth/domain/usecases/watch_auth_session.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/cubits/forgot_password_cubit.dart';
import '../../features/auth/presentation/cubits/login_cubit.dart';
import '../../features/auth/presentation/cubits/reset_password_cubit.dart';
import '../../features/auth/presentation/cubits/sign_up_cubit.dart';
import '../../features/auth/presentation/cubits/welcome_cubit.dart';
import '../../features/generator/domain/usecases/generate_password.dart';
import '../../features/generator/presentation/cubit/generator_cubit.dart';
import '../../features/home/presentation/cubit/home_tab_cubit.dart';
import '../../features/settings/data/datasources/theme_local_data_source.dart';
import '../../features/settings/data/repositories/theme_repository_impl.dart';
import '../../features/settings/domain/repositories/theme_repository.dart';
import '../../features/settings/domain/usecases/load_theme_mode.dart';
import '../../features/settings/domain/usecases/set_theme_mode.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/settings/presentation/cubit/theme_cubit.dart';
import '../../features/vault/data/datasources/vault_local_data_source.dart';
import '../../features/vault/data/repositories/vault_repository_impl.dart';
import '../../features/vault/domain/entities/vault_item.dart';
import '../../features/vault/domain/repositories/vault_repository.dart';
import '../../features/vault/domain/usecases/delete_vault_item.dart';
import '../../features/vault/domain/usecases/get_vault.dart';
import '../../features/vault/domain/usecases/load_vault.dart';
import '../../features/vault/domain/usecases/save_vault_item.dart';
import '../../features/vault/domain/usecases/toggle_favourite.dart';
import '../../features/vault/domain/usecases/watch_vault.dart';
import '../../features/vault/presentation/bloc/vault_bloc.dart';
import '../../features/vault/presentation/cubits/login_form_cubit.dart';
import '../../features/vault/presentation/cubits/password_detail_cubit.dart';
import '../../features/vault/presentation/cubits/vault_filter_cubit.dart';

/// The app's service locator.
final sl = GetIt.instance;

/// Registers everything. Tests pass fakes for the device-facing parts.
///
/// Data sources, repositories, use cases and the app-wide blocs are
/// singletons; screen cubits are factories, created per page by a
/// `BlocProvider`.
void configureDependencies({
  FlutterSecureStorage storage = fusionStorage,
  BiometricAuth? biometrics,
  PasswordHasher hasher = hashInBackground,
}) {
  // ── External ──
  sl
    ..registerLazySingleton<BiometricAuth>(
      () => biometrics ?? LocalBiometricAuth(),
    )
    ..registerLazySingleton(DioClient.new)
    ..registerLazySingleton(DraftPassword.new);

  // ── Data ──
  sl
    ..registerLazySingleton<AuthLocalDataSource>(
      () => SecureAuthLocalDataSource(storage),
    )
    ..registerLazySingleton<AppLockLocalDataSource>(
      () => SecureAppLockLocalDataSource(storage),
    )
    ..registerLazySingleton<VaultLocalDataSource>(
      () => SecureVaultLocalDataSource(storage),
    )
    ..registerLazySingleton<ThemeLocalDataSource>(
      () => SecureThemeLocalDataSource(storage),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl(), hasher: hasher),
    )
    ..registerLazySingleton<AppLockRepository>(
      () => AppLockRepositoryImpl(sl(), biometrics: sl(), hasher: hasher),
    )
    ..registerLazySingleton<VaultRepository>(() => VaultRepositoryImpl(sl()))
    ..registerLazySingleton<ThemeRepository>(() => ThemeRepositoryImpl(sl()));

  // ── Domain ──
  sl
    // auth
    ..registerLazySingleton(() => InitAuth(sl()))
    ..registerLazySingleton(() => GetAuthSession(sl()))
    ..registerLazySingleton(() => WatchAuthSession(sl()))
    ..registerLazySingleton(() => SignUp(sl(), sl()))
    ..registerLazySingleton(() => LogInWithPassword(sl(), sl()))
    ..registerLazySingleton(() => RequestPasswordReset(sl()))
    ..registerLazySingleton(() => GetPendingResetEmail(sl()))
    ..registerLazySingleton(() => ResetPassword(sl()))
    ..registerLazySingleton(() => UnlockWithAppLock(sl(), sl()))
    ..registerLazySingleton(() => LockVault(sl(), sl(), sl()))
    ..registerLazySingleton(() => UseMasterPasswordInstead(sl(), sl(), sl()))
    ..registerLazySingleton(() => EraseEverything(sl(), sl(), sl()))
    // app lock
    ..registerLazySingleton(() => InitAppLock(sl()))
    ..registerLazySingleton(() => GetAppLockStatus(sl()))
    ..registerLazySingleton(() => WatchAppLockStatus(sl()))
    ..registerLazySingleton(() => RefreshBiometrics(sl()))
    ..registerLazySingleton(() => SetPin(sl()))
    ..registerLazySingleton(() => VerifyPin(sl()))
    ..registerLazySingleton(() => SetBiometric(sl()))
    ..registerLazySingleton(() => TryBiometric(sl()))
    ..registerLazySingleton(() => ConfirmBiometric(sl()))
    ..registerLazySingleton(() => ConsumeSkipAutoPrompt(sl()))
    ..registerLazySingleton(() => CancelMasterPassword(sl()))
    ..registerLazySingleton(() => ShouldLockOnHide(sl(), sl()))
    // vault
    ..registerLazySingleton(() => LoadVault(sl()))
    ..registerLazySingleton(() => GetVault(sl()))
    ..registerLazySingleton(() => WatchVault(sl()))
    ..registerLazySingleton(() => SaveVaultItem(sl()))
    ..registerLazySingleton(() => DeleteVaultItem(sl()))
    ..registerLazySingleton(() => ToggleFavourite(sl()))
    // generator
    ..registerLazySingleton(GeneratePassword.new)
    // settings
    ..registerLazySingleton(() => LoadThemeMode(sl()))
    ..registerLazySingleton(() => SetThemeMode(sl()));

  // ── Presentation: app-wide ──
  sl
    ..registerLazySingleton(
      () => AuthBloc(getSession: sl(), watchSession: sl()),
    )
    ..registerLazySingleton(
      () => AppLockBloc(
        getStatus: sl(),
        watchStatus: sl(),
        watchSession: sl(),
        shouldLockOnHide: sl(),
      ),
    )
    ..registerLazySingleton(
      () => VaultBloc(
        getVault: sl(),
        watchVault: sl(),
        loadVault: sl(),
        toggleFavourite: sl(),
      ),
    )
    ..registerLazySingleton(
      () => ThemeCubit(loadThemeMode: sl(), setThemeMode: sl()),
    );

  // ── Presentation: per screen ──
  sl
    ..registerFactory(() => WelcomeCubit(generatePassword: sl()))
    ..registerFactory(
      () =>
          LoginCubit(getSession: sl(), logIn: sl(), cancelMasterPassword: sl()),
    )
    ..registerFactory(() => SignUpCubit(signUp: sl()))
    ..registerFactory(
      () => ForgotPasswordCubit(getSession: sl(), requestReset: sl()),
    )
    ..registerFactory(
      () => ResetPasswordCubit(
        getPendingEmail: sl(),
        requestReset: sl(),
        resetPassword: sl(),
      ),
    )
    ..registerFactoryParam<LockCubit, bool, void>(
      (resume, _) => LockCubit(
        resume: resume,
        getStatus: sl(),
        verifyPin: sl(),
        tryBiometric: sl(),
        consumeSkipAutoPrompt: sl(),
        unlockWithAppLock: sl(),
        useMasterPassword: sl(),
      ),
    )
    ..registerFactoryParam<AppLockSetupCubit, bool, void>(
      (change, _) => AppLockSetupCubit(
        change: change,
        getSession: sl(),
        getStatus: sl(),
        verifyPin: sl(),
        setPin: sl(),
        setBiometric: sl(),
        confirmBiometric: sl(),
      ),
    )
    ..registerFactory(HomeTabCubit.new)
    ..registerFactoryParam<VaultFilterCubit, bool, void>(
      (favouritesOnly, _) => VaultFilterCubit(favouritesOnly: favouritesOnly),
    )
    ..registerFactoryParam<LoginFormCubit, VaultItem?, String?>(
      (existing, initialPassword) => LoginFormCubit(
        existing: existing,
        initialPassword: initialPassword,
        saveVaultItem: sl(),
      ),
    )
    ..registerFactoryParam<PasswordDetailCubit, String, void>(
      (itemId, _) => PasswordDetailCubit(
        itemId: itemId,
        getVault: sl(),
        watchVault: sl(),
        toggleFavourite: sl(),
        deleteVaultItem: sl(),
      ),
    )
    ..registerFactory(() => GeneratorCubit(generatePassword: sl()))
    ..registerFactory(
      () => SettingsCubit(
        setBiometric: sl(),
        confirmBiometric: sl(),
        lockVault: sl(),
        eraseEverything: sl(),
      ),
    );
}
