import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/screens/app_lock_setup_screen.dart';
import 'package:fusion/services/app_lock_controller.dart';
import 'package:fusion/services/auth_service.dart';
import 'package:fusion/services/biometric_auth.dart';
import 'package:fusion/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

Future<(AuthService, AppLockController, FakeBiometricAuth)> _env({
  BiometricKind kind = BiometricKind.none,
  bool bioResult = true,
  String? existingPinHash,
  PinHasher hasher = fastHash,
}) async {
  FlutterSecureStorage.setMockInitialValues({
    'fusion.account.v1': jsonEncode({
      'name': 'Ada Lovelace',
      'email': 'ada@x.io',
      'salt': 's',
      'hash': 'h',
    }),
    if (existingPinHash != null)
      'fusion.applock.v1': jsonEncode({
        'salt': 's',
        'hash': existingPinHash,
        'biometric': false,
        'failed': 0,
      }),
  });
  final auth = AuthService();
  await auth.init();
  auth.unlockWithAppLock();
  final bio = FakeBiometricAuth(kind: kind, result: bioResult);
  final lock = AppLockController(auth: auth, biometrics: bio, hasher: hasher);
  await lock.init();
  return (auth, lock, bio);
}

Future<void> _type(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.text(d));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(
    WidgetTester tester,
    AuthService auth,
    AppLockController lock,
    Widget home,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider<AppLockController>.value(value: lock),
        ],
        child: MaterialApp(
          theme: buildFusionTheme(FC.light, Brightness.light),
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('first setup', () {
    testWidgets('create and confirm saves the PIN', (tester) async {
      final (auth, lock, _) = await _env();
      await pump(tester, auth, lock, const AppLockSetupScreen());
      expect(find.text('Create a PIN'), findsOneWidget);
      await _type(tester, '135790');
      expect(find.text('Confirm your PIN'), findsOneWidget);
      expect(lock.hasPin, isFalse);
      await _type(tester, '135790');
      expect(lock.hasPin, isTrue);
      expect(await lock.verifyPin('135790'), isTrue);
    });

    testWidgets('has no way to skip or go back', (tester) async {
      final (auth, lock, _) = await _env();
      await pump(tester, auth, lock, const AppLockSetupScreen());
      expect(find.bySemanticsLabel('Back'), findsNothing);
      expect(find.text('Not now'), findsNothing);
    });

    testWidgets('a mismatch starts over', (tester) async {
      final (auth, lock, _) = await _env();
      await pump(tester, auth, lock, const AppLockSetupScreen());
      await _type(tester, '135790');
      await _type(tester, '135791');
      expect(find.text('PINs didn’t match. Try again.'), findsOneWidget);
      expect(find.text('Create a PIN'), findsOneWidget);
      expect(lock.hasPin, isFalse);
    });

    testWidgets('offers biometrics after the PIN and can skip them', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final (auth, lock, bio) = await _env(kind: BiometricKind.face);
      await pump(tester, auth, lock, const AppLockSetupScreen());
      await _type(tester, '135790');
      await _type(tester, '135790');
      expect(find.text('Use Face ID?'), findsOneWidget);
      expect(lock.hasPin, isFalse);
      await tester.tap(find.text('Not now'));
      // Saving shows a spinner until the app swaps to the vault.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(lock.hasPin, isTrue);
      expect(lock.biometricEnabled, isFalse);
      expect(bio.prompts, 0);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('turns biometrics on after a real prompt', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final (auth, lock, bio) = await _env(kind: BiometricKind.face);
      await pump(tester, auth, lock, const AppLockSetupScreen());
      await _type(tester, '135790');
      await _type(tester, '135790');
      await tester.tap(find.text('Use Face ID'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(bio.prompts, 1);
      expect(lock.hasPin, isTrue);
      expect(lock.biometricEnabled, isTrue);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('a failed prompt keeps the choice open', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final (auth, lock, _) = await _env(
        kind: BiometricKind.face,
        bioResult: false,
      );
      await pump(tester, auth, lock, const AppLockSetupScreen());
      await _type(tester, '135790');
      await _type(tester, '135790');
      await tester.tap(find.text('Use Face ID'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Couldn’t verify Face ID. Try again.'), findsOneWidget);
      expect(lock.hasPin, isFalse);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('change PIN', () {
    Future<(AuthService, AppLockController)> pumpChange(
      WidgetTester tester, {
      PinHasher hasher = fastHash,
    }) async {
      final (auth, lock, _) = await _env(
        existingPinHash: 's|123456',
        hasher: hasher,
      );
      await pump(
        tester,
        auth,
        lock,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AppLockSetupScreen(change: true),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return (auth, lock);
    }

    testWidgets('skips the current PIN after a master password login', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({});
      final auth = AuthService();
      await tester.runAsync(() async {
        await auth.init();
        await auth.signUp(name: 'Ada', email: 'ada@x.io', password: 'pw');
      });
      final lock = AppLockController(
        auth: auth,
        biometrics: FakeBiometricAuth(kind: BiometricKind.none),
        hasher: fastHash,
      );
      await lock.init();
      await lock.setPin('123456');
      await pump(tester, auth, lock, const AppLockSetupScreen(change: true));
      expect(find.text('Create a PIN'), findsOneWidget);
    });

    testWidgets('asks for the current PIN first', (tester) async {
      final (_, lock) = await pumpChange(tester);
      expect(find.text('Enter your current PIN'), findsOneWidget);
      await _type(tester, '000000');
      expect(find.text('Wrong PIN · 4 tries left'), findsOneWidget);
      expect(lock.failedAttempts, 1);
    });

    testWidgets('replaces the PIN and closes', (tester) async {
      final (_, lock) = await pumpChange(tester);
      await _type(tester, '123456');
      expect(find.text('Create a PIN'), findsOneWidget);
      await _type(tester, '246802');
      await _type(tester, '246802');
      expect(find.byType(AppLockSetupScreen), findsNothing);
      expect(await lock.verifyPin('246802'), isTrue);
    });

    testWidgets('closes only itself if the lock covered it mid-save', (
      tester,
    ) async {
      var hold = false;
      final saving = Completer<void>();
      Future<String> slowHash(String salt, String pin) async {
        if (hold) await saving.future;
        return fastHash(salt, pin);
      }

      final (_, lock) = await pumpChange(tester, hasher: slowHash);
      await _type(tester, '123456');
      await _type(tester, '246802');
      // Last digit kicks off the save; the app is locked before it finishes.
      hold = true;
      for (final d in '24680'.split('')) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      await tester.tap(find.text('2'));
      await tester.pump();
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('lock stand-in')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      hold = false;
      saving.complete();
      await tester.pumpAndSettle();
      expect(find.text('lock stand-in'), findsOneWidget);
      expect(await lock.verifyPin('246802'), isTrue);
      nav.pop();
      await tester.pumpAndSettle();
      expect(find.byType(AppLockSetupScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('can be cancelled', (tester) async {
      await pumpChange(tester);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(AppLockSetupScreen), findsNothing);
    });
  });
}
