import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/app/di/injection.dart';
import 'package:fusion/app/router/routes.dart';
import 'package:fusion/core/theme/theme.dart';
import 'package:fusion/core/widgets/components.dart';
import 'package:fusion/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:fusion/features/app_lock/presentation/pages/lock_page.dart';
import 'package:fusion/features/app_lock/presentation/widgets/pin_pad.dart';
import 'package:fusion/features/auth/domain/repositories/auth_repository.dart';
import 'package:fusion/features/auth/presentation/pages/login_page.dart';
import 'package:fusion/features/settings/domain/entities/app_theme_mode.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/pump_fusion.dart';

final _iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

bool get _loggedIn => sl<AuthRepository>().current.loggedIn;

void main() {
  group('launch', () {
    testWidgets('centres its content on screen', (tester) async {
      // Wide enough that the title doesn't wrap, so it can't stretch the
      // column to full width by itself.
      await pumpFusion(tester, size: const Size(1000, 1000));
      for (final f in [
        find.byType(FusionLogo),
        find.byType(PinDots),
        find.byType(PinPad),
      ]) {
        expect(tester.getCenter(f).dx, 500);
      }
    });

    group('theme', () {
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
        await pumpFusion(tester, theme: AppThemeMode.light);
        expect(background(tester), FC.light.violet);
        expect(titleColor(tester), Colors.white);
        expect(tester.widget<PinPad>(find.byType(PinPad)).onDark, isTrue);
      });

      testWidgets('dark mode uses the dark page and surfaces', (tester) async {
        await pumpFusion(tester, theme: AppThemeMode.dark);
        expect(background(tester), FC.dark.bg);
        expect(titleColor(tester), FC.dark.ink);
        expect(tester.widget<PinPad>(find.byType(PinPad)).onDark, isFalse);
        expect(tester.widget<PinDots>(find.byType(PinDots)).onDark, isFalse);
      });
    });

    testWidgets('greets the user by first name', (tester) async {
      await pumpFusion(tester);
      expect(find.text('Welcome back, Ada'), findsOneWidget);
    });

    testWidgets('the right PIN opens the vault', (tester) async {
      await pumpFusion(tester);
      await typePin(tester, '123456');
      expect(_loggedIn, isTrue);
    });

    testWidgets('a wrong PIN says how many tries are left', (tester) async {
      await pumpFusion(tester);
      await typePin(tester, '111111');
      expect(_loggedIn, isFalse);
      expect(find.text('Wrong PIN · 4 tries left'), findsOneWidget);
      expect(find.bySemanticsLabel('0 of 6 digits entered'), findsOneWidget);
    });

    testWidgets('the fifth wrong PIN disables the pad', (tester) async {
      await pumpFusion(tester, failed: 4);
      await typePin(tester, '111111');
      expect(
        find.text('Too many attempts. Use your master password.'),
        findsOneWidget,
      );
      await tester.tap(find.text('1'), warnIfMissed: false);
      await tester.pump();
      expect(find.bySemanticsLabel('0 of 6 digits entered'), findsOneWidget);
      expect(sl<AppLockRepository>().current.pinLockedOut, isTrue);
    });

    testWidgets('prompts for biometrics on open when enabled', (tester) async {
      final h = await pumpFusion(tester, biometric: true);
      await pumpFor(tester);
      expect(h.bio.prompts, 1);
      expect(_loggedIn, isTrue);
    });

    testWidgets('no automatic prompt right after a manual lock', (
      tester,
    ) async {
      final h = await pumpFusion(
        tester,
        biometric: true,
        before: () => sl<AppLockRepository>().skipNextAutoPrompt(),
      );
      expect(h.bio.prompts, 0);
      expect(_loggedIn, isFalse);
      // The owner can still ask for it.
      await tester.tap(find.bySemanticsLabel('Use Face ID'));
      await pumpFor(tester);
      expect(h.bio.prompts, 1);
      expect(_loggedIn, isTrue);
    }, variant: _iOS);

    testWidgets('a failed biometric leaves the PIN pad usable', (tester) async {
      final h = await pumpFusion(tester, biometric: true, bioResult: false);
      await pumpFor(tester);
      expect(_loggedIn, isFalse);
      await tester.tap(find.bySemanticsLabel('Use Face ID'));
      await pumpFor(tester);
      expect(h.bio.prompts, 2);
      await typePin(tester, '123456');
      expect(_loggedIn, isTrue);
    }, variant: _iOS);

    testWidgets('no biometric prompt or key when it is off', (tester) async {
      final h = await pumpFusion(tester);
      await pumpFor(tester);
      expect(h.bio.prompts, 0);
      expect(find.bySemanticsLabel('Use Face ID'), findsNothing);
      expect(find.text('Enter your PIN'), findsOneWidget);
    }, variant: _iOS);

    testWidgets('can fall back to the master password', (tester) async {
      await pumpFusion(tester);
      await tester.tap(find.text('Use master password instead'));
      await pumpFor(tester);
      expect(sl<AppLockRepository>().current.masterPasswordRequested, isTrue);
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });

  group('resume', () {
    Future<void> pumpResume(WidgetTester tester) async {
      await pumpFusion(tester, loggedIn: true);
      unawaited(sl<GoRouter>().push(Routes.newItem));
      await pumpFor(tester);
      toBackground(tester);
      await tester.pump();
      toForeground(tester);
      await pumpFor(tester);
      expect(find.byType(LockPage), findsOneWidget);
    }

    testWidgets('the right PIN returns to the same screen', (tester) async {
      await pumpResume(tester);
      await typePin(tester, '123456');
      expect(find.byType(LockPage), findsNothing);
      expect(find.text('Save a login'), findsOneWidget);
      expect(_loggedIn, isTrue);
    });

    testWidgets('the master password fallback locks the vault fully', (
      tester,
    ) async {
      await pumpResume(tester);
      await tester.tap(find.text('Use master password instead'));
      await pumpFor(tester);
      await pumpFor(tester);
      expect(find.byType(LockPage), findsNothing);
      expect(find.text('Save a login'), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(_loggedIn, isFalse);
      expect(sl<AppLockRepository>().current.masterPasswordRequested, isTrue);
    });
  });
}
