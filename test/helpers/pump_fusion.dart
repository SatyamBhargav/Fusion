import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/app/app.dart';
import 'package:fusion/app/di/injection.dart';
import 'package:fusion/core/security/hashing.dart';
import 'package:fusion/features/app_lock/domain/entities/biometric_kind.dart';
import 'package:fusion/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:fusion/features/settings/domain/entities/app_theme_mode.dart';
import 'package:fusion/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../fakes.dart';
import 'di.dart';

export 'seeds.dart' show vaultItemJson;

/// What a black-box test can still reach once the real app is running.
class FusionHarness {
  FusionHarness(this.bio);

  final FakeBiometricAuth bio;
}

/// Pumps the whole app with seeded storage. The account is Ada Lovelace
/// (ada@x.io, master password `pw`) and the PIN is 123456.
Future<FusionHarness> pumpFusion(
  WidgetTester tester, {
  bool account = true,
  bool pin = true,
  bool loggedIn = false,
  bool biometric = false,
  bool bioResult = true,
  int failed = 0,
  bool masterPasswordRequested = false,
  BiometricKind kind = BiometricKind.face,
  AppThemeMode theme = AppThemeMode.system,
  List<Map<String, Object?>> items = const [],
  Size size = const Size(600, 1000),
  PasswordHasher hasher = fastHash,

  /// Runs after the services are set up, before the app is pumped.
  FutureOr<void> Function()? before,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  PackageInfo.setMockInitialValues(
    appName: 'Fusion',
    packageName: 'app.fusion',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final bio = await setUpDi(
    account: account,
    pin: pin,
    loggedIn: loggedIn,
    biometric: biometric,
    failed: failed,
    items: items,
    bio: FakeBiometricAuth(kind: kind, result: bioResult),
    hasher: hasher,
  );
  if (masterPasswordRequested) {
    sl<AppLockRepository>().requestMasterPassword();
  }
  await before?.call();
  await sl<ThemeCubit>().load();
  await sl<ThemeCubit>().select(theme);
  await tester.pumpWidget(const FusionApp());
  // Some screens loop an animation, so pump a fixed time instead of settling.
  await pumpFor(tester);
  return FusionHarness(bio);
}

void toBackground(WidgetTester tester) {
  for (final s in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}

void toForeground(WidgetTester tester) {
  for (final s in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}

Future<void> typePin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.text(d).last);
    await tester.pump();
  }
  await pumpFor(tester);
}

/// Pumps frame by frame for [d], so delayed entrance animations finish
/// (one big pump would only start them). Screens with looping animations
/// never settle, so this stands in for pumpAndSettle.
Future<void> pumpFor(
  WidgetTester tester, [
  Duration d = const Duration(seconds: 1),
]) async {
  const step = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < d; t += step) {
    await tester.pump(step);
  }
}

/// Lets real async work (hashing isolates) finish, then pumps frames.
Future<void> settleReal(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
  await tester.pump();
  await pumpFor(tester);
}
