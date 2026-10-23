import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/app/di/injection.dart';
import 'package:fusion/app/router/routes.dart';
import 'package:fusion/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:fusion/features/app_lock/presentation/pages/app_lock_setup_page.dart';
import 'package:fusion/features/app_lock/presentation/pages/lock_page.dart';
import 'package:fusion/features/auth/domain/repositories/auth_repository.dart';
import 'package:fusion/features/auth/presentation/pages/login_page.dart';
import 'package:fusion/features/auth/presentation/pages/welcome_page.dart';
import 'package:fusion/features/home/presentation/pages/home_page.dart';
import 'package:go_router/go_router.dart';

import '../helpers/pump_fusion.dart';

Iterable<String> _fieldTexts(WidgetTester tester) => tester
    .widgetList<EditableText>(find.byType(EditableText))
    .map((e) => e.controller.text);

Future<void> _openNewLogin(WidgetTester tester) async {
  unawaited(sl<GoRouter>().push(Routes.newItem));
  await pumpFor(tester);
  await tester.enterText(find.byType(EditableText).first, 'half-filled');
}

Future<void> _leaveAndReturn(WidgetTester tester) async {
  toBackground(tester);
  await tester.pump();
  toForeground(tester);
  await pumpFor(tester);
}

void main() {
  group('the app picks the screen', () {
    testWidgets('no account → welcome', (tester) async {
      await pumpFusion(tester, account: false, pin: false);
      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('account without a PIN → master password login', (
      tester,
    ) async {
      await pumpFusion(tester, pin: false);
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('account with a PIN → lock', (tester) async {
      await pumpFusion(tester);
      expect(find.byType(LockPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('asking for the master password → login', (tester) async {
      await pumpFusion(tester);
      sl<AppLockRepository>().requestMasterPassword();
      await pumpFor(tester);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(LockPage), findsNothing);
    });

    testWidgets('logged in without a PIN → mandatory setup', (tester) async {
      await pumpFusion(tester, pin: false, loggedIn: true);
      expect(find.byType(AppLockSetupPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets('logged in with a PIN → vault', (tester) async {
      await pumpFusion(tester, loggedIn: true);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('unlocking from the lock opens the vault', (tester) async {
      await pumpFusion(tester);
      await typePin(tester, '123456');
      expect(sl<AuthRepository>().current.loggedIn, isTrue);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('a screen outside the current state redirects', (tester) async {
      await pumpFusion(tester);
      sl<GoRouter>().go(Routes.home);
      await pumpFor(tester);
      expect(find.byType(LockPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });
  });

  group('lock on return', () {
    testWidgets('covers the current screen and returns to it', (tester) async {
      await pumpFusion(tester, loggedIn: true);
      await _openNewLogin(tester);
      await _leaveAndReturn(tester);
      expect(find.byType(LockPage), findsOneWidget);

      await typePin(tester, '123456');
      expect(find.byType(LockPage), findsNothing);
      expect(find.text('Save a login'), findsOneWidget);
      expect(_fieldTexts(tester), contains('half-filled'));
    });

    testWidgets('a screen closing itself underneath keeps the lock', (
      tester,
    ) async {
      await pumpFusion(tester, loggedIn: true);
      await _openNewLogin(tester);
      await _leaveAndReturn(tester);
      // E.g. a save that finished while the app was away.
      sl<GoRouter>().pop();
      await pumpFor(tester);
      expect(find.byType(LockPage), findsOneWidget);

      // Animations under the lock are paused; the form finishes closing
      // once the vault is unlocked.
      await typePin(tester, '123456');
      expect(find.byType(LockPage), findsNothing);
      expect(find.text('Save a login'), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('back does not dismiss the lock or the page under it', (
      tester,
    ) async {
      await pumpFusion(tester, loggedIn: true);
      await _openNewLogin(tester);
      await _leaveAndReturn(tester);
      await tester.binding.handlePopRoute();
      await pumpFor(tester);
      expect(find.byType(LockPage), findsOneWidget);
      await typePin(tester, '123456');
      expect(find.text('Save a login'), findsOneWidget);
    });

    testWidgets('only one lock even if hidden twice', (tester) async {
      await pumpFusion(tester, loggedIn: true);
      toBackground(tester);
      toForeground(tester);
      await tester.pump();
      toBackground(tester);
      toForeground(tester);
      await pumpFor(tester);
      expect(find.byType(LockPage), findsOneWidget);
    });

    testWidgets('still locks if sent home right after a biometric prompt', (
      tester,
    ) async {
      await pumpFusion(tester, loggedIn: true);
      // The sheet itself only makes the app inactive; a hide right after it
      // is the user really leaving.
      await sl<AppLockRepository>().confirmBiometric('test');
      await _leaveAndReturn(tester);
      expect(find.byType(LockPage), findsOneWidget);
    });

    testWidgets('does not lock during setup (no PIN yet)', (tester) async {
      await pumpFusion(tester, pin: false, loggedIn: true);
      await _leaveAndReturn(tester);
      expect(find.byType(LockPage), findsNothing);
      expect(find.byType(AppLockSetupPage), findsOneWidget);
    });

    testWidgets('does not lock when already logged out', (tester) async {
      await pumpFusion(tester, pin: false);
      await _leaveAndReturn(tester);
      expect(find.byType(LockPage), findsNothing);
    });
  });
}
