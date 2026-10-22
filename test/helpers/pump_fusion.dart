import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/main.dart';
import 'package:fusion/services/app_lock_controller.dart';
import 'package:fusion/services/auth_service.dart';
import 'package:fusion/services/biometric_auth.dart';
import 'package:fusion/services/theme_controller.dart';
import 'package:fusion/services/vault_store.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../fakes.dart';

/// What a black-box test can still reach once the real app is running.
class FusionHarness {
  FusionHarness(this.bio);

  final FakeBiometricAuth bio;
}

Map<String, Object?> vaultItemJson({
  required String id,
  required String name,
  String website = '',
  String username = '',
  String password = 'pw-123456',
  bool favourite = false,
}) => {
  'id': id,
  'name': name,
  'website': website,
  'username': username,
  'password': password,
  'note': '',
  'favourite': favourite,
  'kind': 'password',
  'provider': 'google',
  'updatedAt': '2026-01-01T00:00:00.000',
};

/// Pumps the whole app with seeded storage. The account is Ada Lovelace
/// (ada@x.io) and the PIN is 123456.
Future<FusionHarness> pumpFusion(
  WidgetTester tester, {
  bool account = true,
  bool pin = true,
  bool loggedIn = false,
  bool biometric = false,
  BiometricKind kind = BiometricKind.face,
  List<Map<String, Object?>> items = const [],
  Size size = const Size(600, 1000),
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  FlutterSecureStorage.setMockInitialValues({
    if (account)
      'fusion.account.v1': jsonEncode({
        'name': 'Ada Lovelace',
        'email': 'ada@x.io',
        'salt': 's',
        'hash': 'h',
      }),
    if (pin)
      'fusion.applock.v1': jsonEncode({
        'salt': 's',
        'hash': 's|123456',
        'biometric': biometric,
        'failed': 0,
      }),
    if (items.isNotEmpty) 'fusion.vault.v1': jsonEncode(items),
  });
  final bio = FakeBiometricAuth(kind: kind);
  final auth = AuthService();
  await auth.init();
  if (loggedIn) auth.unlockWithAppLock();
  final lock = AppLockController(auth: auth, biometrics: bio, hasher: fastHash);
  await lock.init();
  final theme = ThemeController();
  await theme.init();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<AppLockController>.value(value: lock),
        ChangeNotifierProvider<ThemeController>.value(value: theme),
        ChangeNotifierProvider<VaultStore>(create: (_) => VaultStore()),
      ],
      child: const FusionApp(),
    ),
  );
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
