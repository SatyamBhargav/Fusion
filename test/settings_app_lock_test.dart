import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/screens/app_lock_setup_screen.dart';
import 'package:fusion/screens/settings_screen.dart';
import 'package:fusion/services/app_lock_controller.dart';
import 'package:fusion/services/auth_service.dart';
import 'package:fusion/services/biometric_auth.dart';
import 'package:fusion/services/theme_controller.dart';
import 'package:fusion/services/vault_store.dart';
import 'package:fusion/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

Future<(AppLockController, FakeBiometricAuth)> _pump(
  WidgetTester tester, {
  BiometricKind kind = BiometricKind.face,
  bool biometric = false,
  bool bioResult = true,
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  FlutterSecureStorage.setMockInitialValues({
    'fusion.account.v1': jsonEncode({
      'name': 'Ada',
      'email': 'ada@x.io',
      'salt': 's',
      'hash': 'h',
    }),
    'fusion.applock.v1': jsonEncode({
      'salt': 's',
      'hash': 's|123456',
      'biometric': biometric,
      'failed': 0,
    }),
  });
  final auth = AuthService();
  await auth.init();
  auth.unlockWithAppLock();
  final bio = FakeBiometricAuth(kind: kind, result: bioResult);
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
        ChangeNotifierProvider(create: (_) => VaultStore()),
      ],
      child: MaterialApp(
        theme: buildFusionTheme(FC.light, Brightness.light),
        home: const Scaffold(body: SettingsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (lock, bio);
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    PackageInfo.setMockInitialValues(
      appName: 'Fusion',
      packageName: 'app.fusion',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('turning biometrics on asks for them first', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final (lock, bio) = await _pump(tester);
    expect(find.text('Unlock with Face ID'), findsOneWidget);
    await tester.tap(find.text('Unlock with Face ID'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(bio.prompts, 1);
    expect(lock.biometricEnabled, isTrue);
    expect(find.text('Ask for your PIN or Face ID'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a failed prompt leaves biometrics off', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final (lock, _) = await _pump(tester, bioResult: false);
    await tester.tap(find.text('Unlock with Face ID'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(lock.biometricEnabled, isFalse);
    expect(find.text('Couldn’t verify Face ID'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('turning biometrics off needs no prompt', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final (lock, bio) = await _pump(tester, biometric: true);
    await tester.tap(find.text('Unlock with Face ID'));
    await tester.pumpAndSettle();
    expect(bio.prompts, 0);
    expect(lock.biometricEnabled, isFalse);
    expect(find.text('Ask for your PIN'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Lock vault locks without an automatic biometric prompt', (
    tester,
  ) async {
    final (lock, _) = await _pump(tester, biometric: true);
    await tester.tap(find.text('Lock vault'));
    await tester.pump();
    expect(lock.consumeSkipAutoPrompt(), isTrue);
    expect(lock.consumeSkipAutoPrompt(), isFalse);
  });

  testWidgets('no biometric switch when the device has none', (tester) async {
    await _pump(tester, kind: BiometricKind.none);
    expect(find.textContaining('Unlock with'), findsNothing);
    expect(find.text('Change PIN'), findsOneWidget);
  });

  testWidgets('Change PIN opens the PIN screen in change mode', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Change PIN'));
    await tester.pumpAndSettle();
    final screen = tester.widget<AppLockSetupScreen>(
      find.byType(AppLockSetupScreen),
    );
    expect(screen.change, isTrue);
    expect(find.text('Enter your current PIN'), findsOneWidget);
  });
}
