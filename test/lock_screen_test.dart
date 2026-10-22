import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/screens/lock_screen.dart';
import 'package:fusion/services/app_lock_controller.dart';
import 'package:fusion/services/auth_service.dart';
import 'package:fusion/services/biometric_auth.dart';
import 'package:fusion/services/vault_store.dart';
import 'package:fusion/theme.dart';
import 'package:fusion/widgets/components.dart';
import 'package:fusion/widgets/pin_pad.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

class _Env {
  _Env(this.auth, this.lock, this.bio, this.vault);
  final AuthService auth;
  final AppLockController lock;
  final FakeBiometricAuth bio;
  final VaultStore vault;
}

/// An account with PIN 123456 already set up.
Future<_Env> _env({
  bool biometric = false,
  int failed = 0,
  BiometricKind kind = BiometricKind.face,
  bool bioResult = true,
}) async {
  FlutterSecureStorage.setMockInitialValues({
    'fusion.account.v1': jsonEncode({
      'name': 'Ada Lovelace',
      'email': 'ada@x.io',
      'salt': 's',
      'hash': 'h',
    }),
    'fusion.applock.v1': jsonEncode({
      'salt': 's',
      'hash': 's|123456',
      'biometric': biometric,
      'failed': failed,
    }),
  });
  final auth = AuthService();
  await auth.init();
  final bio = FakeBiometricAuth(kind: kind, result: bioResult);
  final lock = AppLockController(auth: auth, biometrics: bio, hasher: fastHash);
  await lock.init();
  return _Env(auth, lock, bio, VaultStore());
}

Widget _app(_Env e, Widget home, {ThemeMode mode = ThemeMode.light}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: e.auth),
        ChangeNotifierProvider<AppLockController>.value(value: e.lock),
        ChangeNotifierProvider<VaultStore>.value(value: e.vault),
      ],
      child: MaterialApp(
        theme: buildFusionTheme(FC.light, Brightness.light),
        darkTheme: buildFusionTheme(FC.dark, Brightness.dark),
        themeMode: mode,
        home: home,
      ),
    );

Future<void> _type(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.text(d));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<_Env> pumpLaunch(
    WidgetTester tester, {
    bool biometric = false,
    int failed = 0,
    bool bioResult = true,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final e = await _env(
      biometric: biometric,
      failed: failed,
      bioResult: bioResult,
    );
    await tester.pumpWidget(_app(e, const LockScreen()));
    await tester.pumpAndSettle();
    return e;
  }

  group('launch', () {
    testWidgets('centres its content on screen', (tester) async {
      // Wide enough that the title doesn't wrap, so it can't stretch the
      // column to full width by itself.
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final e = await _env();
      await tester.pumpWidget(_app(e, const LockScreen()));
      await tester.pumpAndSettle();
      for (final f in [
        find.byType(FusionLogo),
        find.byType(PinDots),
        find.byType(PinPad),
      ]) {
        expect(tester.getCenter(f).dx, 500);
      }
    });

    group('theme', () {
      Future<void> pumpIn(WidgetTester tester, ThemeMode mode) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final e = await _env();
        await tester.pumpWidget(_app(e, const LockScreen(), mode: mode));
        await tester.pumpAndSettle();
      }

      Color? background(WidgetTester tester) => tester
          .widget<Scaffold>(
            find.ancestor(
              of: find.byType(PinPad),
              matching: find.byType(Scaffold),
            ),
          )
          .backgroundColor;

      Color? titleColor(WidgetTester tester) =>
          tester.widget<Text>(find.text('Welcome back, Ada')).style?.color;

      testWidgets('light mode is the violet lock', (tester) async {
        await pumpIn(tester, ThemeMode.light);
        expect(background(tester), FC.light.violet);
        expect(titleColor(tester), Colors.white);
        expect(tester.widget<PinPad>(find.byType(PinPad)).onDark, isTrue);
      });

      testWidgets('dark mode uses the dark page and surfaces', (tester) async {
        await pumpIn(tester, ThemeMode.dark);
        expect(background(tester), FC.dark.bg);
        expect(titleColor(tester), FC.dark.ink);
        expect(tester.widget<PinPad>(find.byType(PinPad)).onDark, isFalse);
        expect(tester.widget<PinDots>(find.byType(PinDots)).onDark, isFalse);
      });
    });

    testWidgets('greets the user by first name', (tester) async {
      await pumpLaunch(tester);
      expect(find.text('Welcome back, Ada'), findsOneWidget);
    });

    testWidgets('the right PIN opens the vault', (tester) async {
      final e = await pumpLaunch(tester);
      await _type(tester, '123456');
      expect(e.auth.loggedIn, isTrue);
    });

    testWidgets('a wrong PIN says how many tries are left', (tester) async {
      final e = await pumpLaunch(tester);
      await _type(tester, '111111');
      expect(e.auth.loggedIn, isFalse);
      expect(find.text('Wrong PIN · 4 tries left'), findsOneWidget);
      expect(find.bySemanticsLabel('0 of 6 digits entered'), findsOneWidget);
    });

    testWidgets('the fifth wrong PIN disables the pad', (tester) async {
      final e = await pumpLaunch(tester, failed: 4);
      await _type(tester, '111111');
      expect(
        find.text('Too many attempts. Use your master password.'),
        findsOneWidget,
      );
      await tester.tap(find.text('1'), warnIfMissed: false);
      await tester.pump();
      expect(find.bySemanticsLabel('0 of 6 digits entered'), findsOneWidget);
      expect(e.lock.pinLockedOut, isTrue);
    });

    testWidgets('prompts for biometrics on open when enabled', (tester) async {
      final e = await pumpLaunch(tester, biometric: true);
      await tester.pump(const Duration(milliseconds: 600));
      expect(e.bio.prompts, 1);
      expect(e.auth.loggedIn, isTrue);
    });

    testWidgets('no automatic prompt right after a manual lock', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final e = await _env(biometric: true);
      e.lock.skipNextAutoPrompt();
      await tester.pumpWidget(_app(e, const LockScreen()));
      await tester.pumpAndSettle();
      expect(e.bio.prompts, 0);
      expect(e.auth.loggedIn, isFalse);
      // The owner can still ask for it.
      await tester.tap(find.bySemanticsLabel('Use Face ID'));
      await tester.pumpAndSettle();
      expect(e.bio.prompts, 1);
      expect(e.auth.loggedIn, isTrue);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('a failed biometric leaves the PIN pad usable', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final e = await pumpLaunch(tester, biometric: true, bioResult: false);
      await tester.pump(const Duration(milliseconds: 600));
      expect(e.auth.loggedIn, isFalse);
      await tester.tap(find.bySemanticsLabel('Use Face ID'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(e.bio.prompts, 2);
      await _type(tester, '123456');
      expect(e.auth.loggedIn, isTrue);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('no biometric prompt or key when it is off', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final e = await pumpLaunch(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(e.bio.prompts, 0);
      expect(find.bySemanticsLabel('Use Face ID'), findsNothing);
      expect(find.text('Enter your PIN'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('can fall back to the master password', (tester) async {
      final e = await pumpLaunch(tester);
      await tester.tap(find.text('Use master password instead'));
      await tester.pump();
      expect(e.lock.masterPasswordRequested, isTrue);
    });
  });

  group('resume', () {
    Future<_Env> pumpResume(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final e = await _env();
      e.auth.unlockWithAppLock();
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthService>.value(value: e.auth),
            ChangeNotifierProvider<AppLockController>.value(value: e.lock),
            ChangeNotifierProvider<VaultStore>.value(value: e.vault),
          ],
          child: MaterialApp(
            navigatorKey: nav,
            theme: buildFusionTheme(FC.light, Brightness.light),
            home: const Scaffold(body: Text('vault home')),
          ),
        ),
      );
      nav.currentState!
        ..push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('half-filled form')),
          ),
        )
        ..push(lockRoute());
      await tester.pumpAndSettle();
      return e;
    }

    testWidgets('the right PIN returns to the same screen', (tester) async {
      final e = await pumpResume(tester);
      expect(find.byType(LockScreen), findsOneWidget);
      await _type(tester, '123456');
      expect(find.byType(LockScreen), findsNothing);
      expect(find.text('half-filled form'), findsOneWidget);
      expect(e.auth.loggedIn, isTrue);
    });

    testWidgets('back does not dismiss the lock', (tester) async {
      await pumpResume(tester);
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      await nav.maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(LockScreen), findsOneWidget);
    });

    testWidgets('master password fallback locks the vault fully', (
      tester,
    ) async {
      final e = await pumpResume(tester);
      await tester.tap(find.text('Use master password instead'));
      await tester.pumpAndSettle();
      expect(find.byType(LockScreen), findsNothing);
      expect(find.text('half-filled form'), findsNothing);
      expect(e.auth.loggedIn, isFalse);
      expect(e.lock.masterPasswordRequested, isTrue);
    });
  });
}
