import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/theme.dart';

void main() {
  testWidgets('closeRoute removes only its own route when it is covered', (
    tester,
  ) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: nav, home: const Text('home')),
    );
    late Route<void> form;
    form = MaterialPageRoute<void>(builder: (_) => const Text('form'));
    nav.currentState!
      ..push(form)
      ..push(MaterialPageRoute<void>(builder: (_) => const Text('lock')));
    await tester.pumpAndSettle();

    closeRoute(nav.currentState!, form);
    await tester.pumpAndSettle();
    expect(find.text('lock'), findsOneWidget);

    Navigator.of(tester.element(find.text('lock'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('form'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('closeRoute pops normally when on top', (tester) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: nav, home: const Text('home')),
    );
    final form = MaterialPageRoute<void>(builder: (_) => const Text('form'));
    nav.currentState!.push(form);
    await tester.pumpAndSettle();
    closeRoute(nav.currentState!, form);
    await tester.pumpAndSettle();
    expect(find.text('form'), findsNothing);
  });
}
