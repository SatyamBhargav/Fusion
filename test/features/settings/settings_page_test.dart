import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/app/di/injection.dart';
import 'package:fusion/core/theme/theme.dart';
import 'package:fusion/features/app_lock/domain/entities/biometric_kind.dart';
import 'package:fusion/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:fusion/features/settings/domain/entities/app_theme_mode.dart';
import 'package:fusion/features/settings/domain/repositories/theme_repository.dart';
import 'package:fusion/features/settings/presentation/cubit/theme_cubit.dart';

import '../../helpers/pump_fusion.dart';

final _iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

Future<FusionHarness> _pumpSettings(
  WidgetTester tester, {
  BiometricKind kind = BiometricKind.face,
  bool biometric = false,
  bool bioResult = true,
}) async {
  final h = await pumpFusion(
    tester,
    loggedIn: true,
    kind: kind,
    biometric: biometric,
    bioResult: bioResult,
    size: const Size(600, 1600),
  );
  await tester.tap(find.bySemanticsLabel('Settings'));
  await pumpFor(tester);
  return h;
}

void main() {
  group('app lock', () {
    testWidgets('turning biometrics on asks for them first', (tester) async {
      final h = await _pumpSettings(tester);
      await tester.tap(find.text('Unlock with Face ID'));
      await pumpFor(tester);
      expect(h.bio.prompts, 1);
      expect(sl<AppLockRepository>().current.biometricEnabled, isTrue);
      expect(find.text('Ask for your PIN or Face ID'), findsOneWidget);
    }, variant: _iOS);

    testWidgets('a failed prompt leaves biometrics off', (tester) async {
      await _pumpSettings(tester, bioResult: false);
      await tester.tap(find.text('Unlock with Face ID'));
      await pumpFor(tester);
      expect(sl<AppLockRepository>().current.biometricEnabled, isFalse);
      expect(find.text('Couldn’t verify Face ID'), findsOneWidget);
      await pumpFor(tester, const Duration(seconds: 4));
    }, variant: _iOS);

    testWidgets('turning biometrics off needs no prompt', (tester) async {
      final h = await _pumpSettings(tester, biometric: true);
      await tester.tap(find.text('Unlock with Face ID'));
      await pumpFor(tester);
      expect(h.bio.prompts, 0);
      expect(sl<AppLockRepository>().current.biometricEnabled, isFalse);
      expect(find.text('Ask for your PIN'), findsOneWidget);
    }, variant: _iOS);

    testWidgets('no biometric switch when the device has none', (tester) async {
      await _pumpSettings(tester, kind: BiometricKind.none);
      expect(find.textContaining('Unlock with'), findsNothing);
      expect(find.text('Change PIN'), findsOneWidget);
    });
  });

  testWidgets('the appearance toggle switches the theme and persists', (
    tester,
  ) async {
    await _pumpSettings(tester);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Fusion v1.0.0 (1)'), findsOneWidget);
    expect(sl<ThemeCubit>().state, AppThemeMode.system);

    await tester.tap(find.text('Dark'));
    await pumpFor(tester);
    expect(sl<ThemeCubit>().state, AppThemeMode.dark);
    final ctx = tester.element(find.text('Appearance'));
    expect(Theme.of(ctx).brightness, Brightness.dark);
    expect(ctx.fc.bg, FC.dark.bg);

    await tester.tap(find.text('Light'));
    await pumpFor(tester);
    expect(Theme.of(ctx).brightness, Brightness.light);
    expect(await sl<ThemeRepository>().load(), AppThemeMode.light);
  });

  testWidgets('shows the account and how many logins it holds', (tester) async {
    await pumpFusion(
      tester,
      loggedIn: true,
      items: [
        vaultItemJson(id: 'a', name: 'GitHub'),
        vaultItemJson(id: 'b', name: 'Netflix'),
      ],
      size: const Size(600, 1600),
    );
    await tester.tap(find.bySemanticsLabel('Settings'));
    await pumpFor(tester);
    expect(find.text('ada@x.io'), findsOneWidget);
    expect(find.text('2 logins'), findsOneWidget);
  });
}
