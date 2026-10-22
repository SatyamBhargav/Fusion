import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fusion/app/di/injection.dart';
import 'package:fusion/core/storage/secure_storage.dart';
import 'package:fusion/features/app_lock/domain/usecases/init_app_lock.dart';
import 'package:fusion/features/auth/domain/repositories/auth_repository.dart';
import 'package:fusion/features/auth/domain/usecases/init_auth.dart';

import '../fakes.dart';
import 'seeds.dart';

/// Fresh service locator over seeded mock storage, with stored data read.
Future<FakeBiometricAuth> setUpDi({
  bool account = true,
  bool pin = true,
  bool loggedIn = false,
  bool biometric = false,
  int failed = 0,
  List<Map<String, Object?>> items = const [],
  FakeBiometricAuth? bio,
}) async {
  await sl.reset();
  FlutterSecureStorage.setMockInitialValues({
    if (account) StorageKeys.account: accountSeed,
    if (pin) StorageKeys.appLock: pinSeed(biometric: biometric, failed: failed),
    if (items.isNotEmpty) StorageKeys.vault: jsonEncode(items),
  });
  final fake = bio ?? FakeBiometricAuth();
  configureDependencies(biometrics: fake, hasher: fastHash);
  await sl<InitAuth>()();
  await sl<InitAppLock>()();
  if (loggedIn) sl<AuthRepository>().unlock();
  return fake;
}

/// Lets stream listeners (blocs) catch up.
Future<void> flush() => Future<void>.delayed(Duration.zero);
