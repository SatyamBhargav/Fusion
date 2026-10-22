import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/screens/settings_screen.dart';
import 'package:fusion/services/app_lock_controller.dart';
import 'package:fusion/services/auth_service.dart';
import 'package:fusion/services/theme_controller.dart';
import 'package:fusion/services/vault_store.dart';
import 'package:fusion/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

Future<ThemeController> _pumpSettings(WidgetTester tester) async {
  final theme = ThemeController();
  await theme.init();
  final auth = AuthService();
  final lock = AppLockController(
    auth: auth,
    biometrics: FakeBiometricAuth(),
    hasher: fastHash,
  );
  await lock.init();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<AppLockController>.value(value: lock),
        ChangeNotifierProvider(create: (_) => VaultStore()),
        ChangeNotifierProvider<ThemeController>.value(value: theme),
      ],
      child: Builder(
        builder: (context) => MaterialApp(
          theme: buildFusionTheme(FC.light, Brightness.light),
          darkTheme: buildFusionTheme(FC.dark, Brightness.dark),
          themeMode: context.watch<ThemeController>().mode,
          home: const Scaffold(body: SettingsScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return theme;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Fusion',
      packageName: 'app.fusion',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('appearance toggle switches the theme and persists', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final theme = await _pumpSettings(tester);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Fusion v1.0.0 (1)'), findsOneWidget);
    expect(theme.mode, ThemeMode.system);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(theme.mode, ThemeMode.dark);
    final ctx = tester.element(find.text('Appearance'));
    expect(Theme.of(ctx).brightness, Brightness.dark);
    expect(ctx.fc.bg, FC.dark.bg);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(Theme.of(ctx).brightness, Brightness.light);

    final reloaded = ThemeController();
    await reloaded.init();
    expect(reloaded.mode, ThemeMode.light);
  });
}
