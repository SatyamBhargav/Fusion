import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/app/di/injection.dart';
import 'package:fusion/features/app_lock/domain/entities/biometric_kind.dart';
import 'package:fusion/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:fusion/features/app_lock/presentation/pages/app_lock_setup_page.dart';
import 'package:fusion/features/app_lock/presentation/pages/lock_page.dart';
import 'package:fusion/features/auth/domain/usecases/log_in_with_password.dart';
import 'package:fusion/features/home/presentation/pages/home_page.dart';

import 'package:fusion/core/security/hashing.dart';

import '../../fakes.dart';
import '../../helpers/pump_fusion.dart';

final _iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

AppLockRepository get _lock => sl<AppLockRepository>();

void main() {
  group('first setup', () {
    Future<FusionHarness> pumpSetup(
      WidgetTester tester, {
      BiometricKind kind = BiometricKind.none,
      bool bioResult = true,
    }) => pumpFusion(
      tester,
      pin: false,
      loggedIn: true,
      kind: kind,
      bioResult: bioResult,
    );

    testWidgets('create and confirm saves the PIN and opens the vault', (
      tester,
    ) async {
      await pumpSetup(tester);
      expect(find.text('Create a PIN'), findsOneWidget);
      await typePin(tester, '135790');
      expect(find.text('Confirm your PIN'), findsOneWidget);
      expect(_lock.current.hasPin, isFalse);
      await typePin(tester, '135790');
      expect(_lock.current.hasPin, isTrue);
      expect(await _lock.verifyPin('135790'), isTrue);
      await pumpFor(tester);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('has no way to skip or go back', (tester) async {
      await pumpSetup(tester);
      expect(find.bySemanticsLabel('Back'), findsNothing);
      expect(find.text('Not now'), findsNothing);
      await tester.binding.handlePopRoute();
      await pumpFor(tester);
      expect(find.byType(AppLockSetupPage), findsOneWidget);
    });

    testWidgets('a mismatch starts over', (tester) async {
      await pumpSetup(tester);
      await typePin(tester, '135790');
      await typePin(tester, '135791');
      expect(find.text('PINs didn’t match. Try again.'), findsOneWidget);
      expect(find.text('Create a PIN'), findsOneWidget);
      expect(_lock.current.hasPin, isFalse);
    });

    testWidgets('offers biometrics after the PIN and can skip them', (
      tester,
    ) async {
      final h = await pumpSetup(tester, kind: BiometricKind.face);
      await typePin(tester, '135790');
      await typePin(tester, '135790');
      expect(find.text('Use Face ID?'), findsOneWidget);
      expect(_lock.current.hasPin, isFalse);
      await tester.tap(find.text('Not now'));
      await pumpFor(tester);
      expect(_lock.current.hasPin, isTrue);
      expect(_lock.current.biometricEnabled, isFalse);
      expect(h.bio.prompts, 0);
    }, variant: _iOS);

    testWidgets('turns biometrics on after a real prompt', (tester) async {
      final h = await pumpSetup(tester, kind: BiometricKind.face);
      await typePin(tester, '135790');
      await typePin(tester, '135790');
      await tester.tap(find.text('Use Face ID'));
      await pumpFor(tester);
      expect(h.bio.prompts, 1);
      expect(_lock.current.hasPin, isTrue);
      expect(_lock.current.biometricEnabled, isTrue);
    }, variant: _iOS);

    testWidgets('a failed prompt keeps the choice open', (tester) async {
      await pumpSetup(tester, kind: BiometricKind.face, bioResult: false);
      await typePin(tester, '135790');
      await typePin(tester, '135790');
      await tester.tap(find.text('Use Face ID'));
      await pumpFor(tester);
      expect(find.text('Couldn’t verify Face ID. Try again.'), findsOneWidget);
      expect(_lock.current.hasPin, isFalse);
    }, variant: _iOS);
  });

  group('change PIN', () {
    Future<void> openChange(WidgetTester tester) async {
      await tester.tap(find.bySemanticsLabel('Settings'));
      await pumpFor(tester);
      await tester.tap(find.text('Change PIN'));
      await pumpFor(tester);
    }

    Future<void> pumpChange(
      WidgetTester tester, {
      PasswordHasher hasher = fastHash,
    }) async {
      await pumpFusion(
        tester,
        loggedIn: true,
        kind: BiometricKind.none,
        hasher: hasher,
        size: const Size(600, 1600),
      );
      await openChange(tester);
    }

    testWidgets('skips the current PIN after a master password login', (
      tester,
    ) async {
      await pumpFusion(
        tester,
        kind: BiometricKind.none,
        size: const Size(600, 1600),
        before: () => sl<LogInWithPassword>()(
          const LogInParams(email: 'ada@x.io', password: 'pw'),
        ),
      );
      await openChange(tester);
      expect(find.text('Create a PIN'), findsOneWidget);
    });

    testWidgets('asks for the current PIN first', (tester) async {
      await pumpChange(tester);
      expect(
        tester.widget<AppLockSetupPage>(find.byType(AppLockSetupPage)).change,
        isTrue,
      );
      expect(find.text('Enter your current PIN'), findsOneWidget);
      await typePin(tester, '000000');
      expect(find.text('Wrong PIN · 4 tries left'), findsOneWidget);
      expect(_lock.current.failed, 1);
    });

    testWidgets('replaces the PIN and closes', (tester) async {
      await pumpChange(tester);
      await typePin(tester, '123456');
      expect(find.text('Create a PIN'), findsOneWidget);
      await typePin(tester, '246802');
      await typePin(tester, '246802');
      expect(find.byType(AppLockSetupPage), findsNothing);
      expect(find.text('PIN changed'), findsOneWidget);
      expect(await _lock.verifyPin('246802'), isTrue);
      await pumpFor(tester, const Duration(seconds: 4));
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

      await pumpChange(tester, hasher: slowHash);
      await typePin(tester, '123456');
      await typePin(tester, '246802');
      // The last digit starts the save; the app is locked before it ends.
      hold = true;
      for (final d in '24680'.split('')) {
        await tester.tap(find.text(d).last);
        await tester.pump();
      }
      await tester.tap(find.text('2').last);
      await tester.pump();
      toBackground(tester);
      await tester.pump();
      toForeground(tester);
      await pumpFor(tester);
      expect(find.byType(LockPage), findsOneWidget);

      hold = false;
      saving.complete();
      await pumpFor(tester);
      expect(find.byType(LockPage), findsOneWidget);
      expect(await _lock.verifyPin('246802'), isTrue);

      await typePin(tester, '246802');
      await pumpFor(tester);
      expect(find.byType(LockPage), findsNothing);
      expect(find.byType(AppLockSetupPage), findsNothing);
      expect(find.text('Change PIN'), findsOneWidget);
      await pumpFor(tester, const Duration(seconds: 4));
    });

    testWidgets('can be cancelled', (tester) async {
      await pumpChange(tester);
      await tester.tap(find.bySemanticsLabel('Back'));
      await pumpFor(tester);
      expect(find.byType(AppLockSetupPage), findsNothing);
      expect(find.text('Change PIN'), findsOneWidget);
    });
  });
}
