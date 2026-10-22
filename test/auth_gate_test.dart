import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/main.dart';
import 'package:fusion/screens/app_lock_setup_screen.dart';
import 'package:fusion/screens/home_shell.dart';
import 'package:fusion/screens/lock_screen.dart';
import 'package:fusion/screens/login_screen.dart';
import 'package:fusion/screens/welcome_screen.dart';
import 'package:fusion/services/app_lock_controller.dart';
import 'package:fusion/services/auth_service.dart';
import 'package:fusion/services/theme_controller.dart';
import 'package:fusion/services/vault_store.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

final _account = jsonEncode({
  'name': 'Ada Lovelace',
  'email': 'ada@x.io',
  'salt': 's',
  'hash': 'h',
});
final _pin = jsonEncode({
  'salt': 's',
  'hash': 's|123456',
  'biometric': false,
  'failed': 0,
});

Future<(AuthService, AppLockController)> _pumpApp(
  WidgetTester tester, {
  bool account = true,
  bool pin = true,
  bool loggedIn = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  FlutterSecureStorage.setMockInitialValues({
    if (account) 'fusion.account.v1': _account,
    if (pin) 'fusion.applock.v1': _pin,
  });
  final auth = AuthService();
  await auth.init();
  if (loggedIn) auth.unlockWithAppLock();
  final lock = AppLockController(
    auth: auth,
    biometrics: FakeBiometricAuth(),
    hasher: fastHash,
  );
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
  // Welcome has a looping animation, so pump a fixed time instead of settling.
  await tester.pump(const Duration(seconds: 1));
  return (auth, lock);
}

void _toBackground(WidgetTester tester) {
  for (final s in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}

void _toForeground(WidgetTester tester) {
  for (final s in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}

Future<void> _type(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.text(d));
    await tester.pump();
  }
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AuthGate', () {
    testWidgets('no account → welcome', (tester) async {
      await _pumpApp(tester, account: false, pin: false);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('account without a PIN → master password login', (
      tester,
    ) async {
      await _pumpApp(tester, pin: false);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('account with a PIN → lock screen', (tester) async {
      await _pumpApp(tester);
      expect(find.byType(LockScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('asking for the master password → login', (tester) async {
      final (_, lock) = await _pumpApp(tester);
      lock.requestMasterPassword();
      await tester.pump(); // starts the cross-fade
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(); // drops the old screen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);
    });

    testWidgets('logged in without a PIN → mandatory setup', (tester) async {
      await _pumpApp(tester, pin: false, loggedIn: true);
      expect(find.byType(AppLockSetupScreen), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
    });

    testWidgets('logged in with a PIN → vault', (tester) async {
      await _pumpApp(tester, loggedIn: true);
      expect(find.byType(HomeShell), findsOneWidget);
    });

    testWidgets('unlocking from the lock screen opens the vault', (
      tester,
    ) async {
      final (auth, _) = await _pumpApp(tester);
      await _type(tester, '123456');
      expect(auth.loggedIn, isTrue);
      expect(find.byType(HomeShell), findsOneWidget);
    });
  });

  group('lock on return', () {
    testWidgets('locks over the current screen and returns to it', (
      tester,
    ) async {
      await _pumpApp(tester, loggedIn: true);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('half-filled form')),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      _toBackground(tester);
      await tester.pump();
      _toForeground(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LockScreen), findsOneWidget);

      await _type(tester, '123456');
      expect(find.byType(LockScreen), findsNothing);
      expect(find.text('half-filled form'), findsOneWidget);
    });

    testWidgets('a screen popping itself after an await keeps the lock', (
      tester,
    ) async {
      await _pumpApp(tester, loggedIn: true);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      final saving = Completer<void>();
      nav.push(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final n = Navigator.of(context);
                await saving.future; // e.g. a secure-storage write
                n.pop();
              },
              child: const Text('save'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('save'));

      _toBackground(tester);
      await tester.pump();
      saving.complete();
      _toForeground(tester);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LockScreen), findsOneWidget);
    });

    testWidgets('only one lock even if hidden twice', (tester) async {
      await _pumpApp(tester, loggedIn: true);
      _toBackground(tester);
      _toForeground(tester);
      await tester.pump();
      _toBackground(tester);
      _toForeground(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LockScreen), findsOneWidget);
    });

    testWidgets('still locks if sent home right after a biometric prompt', (
      tester,
    ) async {
      final (_, lock) = await _pumpApp(tester, loggedIn: true);
      // The sheet itself only makes the app inactive; a hide right after it
      // is the user really leaving.
      await lock.confirmBiometric('test');
      _toBackground(tester);
      _toForeground(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LockScreen), findsOneWidget);
    });

    testWidgets('does not lock during setup (no PIN yet)', (tester) async {
      await _pumpApp(tester, pin: false, loggedIn: true);
      _toBackground(tester);
      _toForeground(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LockScreen), findsNothing);
      expect(find.byType(AppLockSetupScreen), findsOneWidget);
    });

    testWidgets('does not lock when already logged out', (tester) async {
      await _pumpApp(tester, pin: false);
      _toBackground(tester);
      _toForeground(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LockScreen), findsNothing);
    });
  });
}
