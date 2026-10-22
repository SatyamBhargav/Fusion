import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/theme.dart';
import 'package:fusion/widgets/pin_pad.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildFusionTheme(FC.light, Brightness.light),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('PinPad', () {
    testWidgets('reports digits and backspace', (tester) async {
      final typed = <String>[];
      var back = 0;
      await tester.pumpWidget(
        _host(PinPad(onDigit: typed.add, onBackspace: () => back++)),
      );
      await tester.tap(find.text('4'));
      await tester.tap(find.text('0'));
      await tester.tap(find.bySemanticsLabel('Delete'));
      expect(typed, ['4', '0']);
      expect(back, 1);
    });

    testWidgets('shows the biometric key only when offered', (tester) async {
      await tester.pumpWidget(
        _host(PinPad(onDigit: (_) {}, onBackspace: () {})),
      );
      expect(find.bySemanticsLabel('Use Face ID'), findsNothing);

      var asked = 0;
      await tester.pumpWidget(
        _host(
          PinPad(
            onDigit: (_) {},
            onBackspace: () {},
            onBiometric: () => asked++,
            biometricLabel: 'Face ID',
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Use Face ID'));
      expect(asked, 1);
    });

    testWidgets('ignores taps while disabled', (tester) async {
      final typed = <String>[];
      await tester.pumpWidget(
        _host(PinPad(onDigit: typed.add, onBackspace: () {}, enabled: false)),
      );
      await tester.tap(find.text('7'), warnIfMissed: false);
      expect(typed, isEmpty);
    });
  });

  testWidgets('PinDots announces progress', (tester) async {
    await tester.pumpWidget(_host(const PinDots(filled: 2)));
    expect(find.bySemanticsLabel('2 of 6 digits entered'), findsOneWidget);
  });
}
