// Black-box flows through the real app. They only use what a user sees, so
// they keep passing however the app is wired inside.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_fusion.dart';

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(label));
  await tester.pump();
  await pumpFor(tester);
}

Iterable<String> _fieldTexts(WidgetTester tester) => tester
    .widgetList<EditableText>(find.byType(EditableText))
    .map((e) => e.controller.text);

void main() {
  testWidgets('forgot password → reset → back at login with a toast', (
    tester,
  ) async {
    await pumpFusion(tester, pin: false);
    await tester.tap(find.text('Forgot password?'));
    await tester.pump();
    await pumpFor(tester);
    await tester.tap(find.text('Send reset code'));
    await tester.pump();
    await pumpFor(tester);

    final codePattern = RegExp(r'Fusion reset code (\d{6})');
    final banner = find.bySemanticsLabel(codePattern);
    expect(banner, findsOneWidget);
    final label = tester.getSemantics(banner).label;
    final code = codePattern.firstMatch(label)!.group(1)!;

    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), code);
    await tester.enterText(fields.at(1), 'new-password-1');
    await tester.enterText(fields.at(2), 'new-password-1');
    await tester.pump();
    await tester.tap(find.text('Reset password'));
    await settleReal(tester);

    expect(
      find.text('Password updated. Log in with your new one.'),
      findsOneWidget,
    );
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Check your inbox'), findsNothing);
    // Let the banner and toast time out.
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('erasing the vault goes back to welcome', (tester) async {
    await pumpFusion(tester, loggedIn: true, size: const Size(600, 1600));
    await _openTab(tester, 'Settings');
    await tester.tap(find.text('Erase this vault'));
    await tester.pump();
    await pumpFor(tester);
    await tester.tap(find.text('Erase vault'));
    await tester.pump();
    await pumpFor(tester);
    await pumpFor(tester);
    expect(find.text('I already have an account'), findsOneWidget);
  });

  testWidgets('Lock vault shows the lock without a biometric prompt', (
    tester,
  ) async {
    final h = await pumpFusion(
      tester,
      loggedIn: true,
      biometric: true,
      size: const Size(600, 1600),
    );
    await _openTab(tester, 'Settings');
    await tester.tap(find.text('Lock vault'));
    await tester.pump();
    await pumpFor(tester);
    await pumpFor(tester);
    expect(find.text('Welcome back, Ada'), findsOneWidget);
    expect(h.bio.prompts, 0);
  });

  testWidgets('master password fallback from the resume lock logs out', (
    tester,
  ) async {
    await pumpFusion(tester, loggedIn: true);
    await tester.tap(find.bySemanticsLabel('Save a new login'));
    await tester.pump();
    await pumpFor(tester);
    expect(find.text('Save a login'), findsOneWidget);

    toBackground(tester);
    await tester.pump();
    toForeground(tester);
    await pumpFor(tester);
    expect(find.text('Use master password instead'), findsOneWidget);

    await tester.tap(find.text('Use master password instead'));
    await tester.pump();
    await pumpFor(tester);
    await pumpFor(tester);
    expect(find.text('Use master password instead'), findsNothing);
    expect(find.text('Save a login'), findsNothing);
    expect(find.text('Unlock your vault to continue, Ada.'), findsOneWidget);
  });

  testWidgets('the resume lock returns to a half-filled form', (tester) async {
    await pumpFusion(tester, loggedIn: true);
    await tester.tap(find.bySemanticsLabel('Save a new login'));
    await tester.pump();
    await pumpFor(tester);
    await tester.enterText(find.byType(EditableText).first, 'Half typed');

    toBackground(tester);
    await tester.pump();
    toForeground(tester);
    await pumpFor(tester);
    expect(find.text('Use master password instead'), findsOneWidget);

    await typePin(tester, '123456');
    expect(find.text('Use master password instead'), findsNothing);
    expect(find.text('Save a login'), findsOneWidget);
    expect(_fieldTexts(tester), contains('Half typed'));
  });

  testWidgets('picking a generated password fills the form', (tester) async {
    await pumpFusion(tester, loggedIn: true);
    await tester.tap(find.bySemanticsLabel('Save a new login'));
    await tester.pump();
    await pumpFor(tester);
    expect(_fieldTexts(tester).every((t) => t.isEmpty), isTrue);

    await tester.tap(find.bySemanticsLabel('Generate a password'));
    await tester.pump();
    await pumpFor(tester);
    await tester.tap(find.text('Use this password'));
    await tester.pump();
    await pumpFor(tester);

    expect(find.text('Save a login'), findsOneWidget);
    expect(_fieldTexts(tester).where((t) => t.length == 16), hasLength(1));
  });

  testWidgets('deleting from the detail page removes the login', (
    tester,
  ) async {
    await pumpFusion(
      tester,
      loggedIn: true,
      items: [vaultItemJson(id: 'a1', name: 'GitHub')],
    );
    await pumpFor(tester);
    await tester.tap(find.text('GitHub'));
    await tester.pump();
    await pumpFor(tester);
    await tester.tap(find.bySemanticsLabel('Delete login'));
    await tester.pump();
    await pumpFor(tester);
    await tester.tap(find.text('Delete login'));
    await tester.pump();
    await pumpFor(tester);

    expect(find.text('GitHub deleted'), findsOneWidget);
    expect(find.text('GitHub'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });
}
