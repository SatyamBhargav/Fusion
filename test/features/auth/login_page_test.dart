import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/app/di/injection.dart';
import 'package:fusion/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:fusion/features/app_lock/presentation/pages/lock_page.dart';
import 'package:fusion/features/auth/domain/repositories/auth_repository.dart';
import 'package:fusion/features/auth/presentation/pages/login_page.dart';
import 'package:fusion/features/home/presentation/pages/home_page.dart';

import '../../helpers/pump_fusion.dart';

void main() {
  testWidgets('offers to go back to the PIN', (tester) async {
    await pumpFusion(tester, masterPasswordRequested: true);
    await tester.tap(find.text('Unlock with PIN instead'));
    await pumpFor(tester);
    expect(sl<AppLockRepository>().current.masterPasswordRequested, isFalse);
    expect(find.byType(LockPage), findsOneWidget);
  });

  testWidgets('no PIN link without a PIN', (tester) async {
    await pumpFusion(tester, pin: false);
    expect(find.text('Unlock with PIN instead'), findsNothing);
  });

  testWidgets('no PIN link once the PIN is locked out', (tester) async {
    await pumpFusion(tester, failed: 5, masterPasswordRequested: true);
    expect(find.text('Unlock with PIN instead'), findsNothing);
  });

  testWidgets('a wrong password stays on the login with an error', (
    tester,
  ) async {
    await pumpFusion(tester, pin: false);
    await tester.enterText(find.byType(EditableText).last, 'nope');
    await tester.tap(find.text('Log in'));
    await pumpFor(tester);
    expect(find.text('Wrong master password. Try again.'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('the master password opens the vault and clears strikes', (
    tester,
  ) async {
    await pumpFusion(tester, failed: 5, masterPasswordRequested: true);
    await tester.enterText(find.byType(EditableText).last, 'pw');
    await tester.tap(find.text('Log in'));
    await pumpFor(tester);
    await pumpFor(tester);
    expect(sl<AuthRepository>().current.loggedIn, isTrue);
    expect(sl<AppLockRepository>().current.pinLockedOut, isFalse);
    expect(find.byType(HomePage), findsOneWidget);
  });
}
