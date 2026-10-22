import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/screens/login_screen.dart';
import 'package:fusion/services/app_lock_controller.dart';
import 'package:fusion/services/auth_service.dart';
import 'package:fusion/core/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

Future<AppLockController> _pump(
  WidgetTester tester, {
  bool pin = true,
  int failed = 0,
  bool requested = true,
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  FlutterSecureStorage.setMockInitialValues({
    'fusion.account.v1': jsonEncode({
      'name': 'Ada',
      'email': 'ada@x.io',
      'salt': 's',
      'hash': 'h',
    }),
    if (pin)
      'fusion.applock.v1': jsonEncode({
        'salt': 's',
        'hash': 's|123456',
        'biometric': false,
        'failed': failed,
      }),
  });
  final auth = AuthService();
  await auth.init();
  final lock = AppLockController(
    auth: auth,
    biometrics: FakeBiometricAuth(),
    hasher: fastHash,
  );
  await lock.init();
  if (requested) lock.requestMasterPassword();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<AppLockController>.value(value: lock),
      ],
      child: MaterialApp(
        theme: buildFusionTheme(FC.light, Brightness.light),
        home: const LoginScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return lock;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('offers to go back to the PIN', (tester) async {
    final lock = await _pump(tester);
    await tester.tap(find.text('Unlock with PIN instead'));
    await tester.pump();
    expect(lock.masterPasswordRequested, isFalse);
  });

  testWidgets('no PIN link without a PIN', (tester) async {
    await _pump(tester, pin: false, requested: false);
    expect(find.text('Unlock with PIN instead'), findsNothing);
  });

  testWidgets('no PIN link once the PIN is locked out', (tester) async {
    await _pump(tester, failed: 5);
    expect(find.text('Unlock with PIN instead'), findsNothing);
  });
}
