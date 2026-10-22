import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/services/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeController', () {
    test('defaults to system when nothing is stored', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final c = ThemeController();
      await c.init();
      expect(c.mode, ThemeMode.system);
    });

    test('persists the chosen mode across instances', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final c = ThemeController();
      await c.init();
      await c.setMode(ThemeMode.dark);
      expect(c.mode, ThemeMode.dark);

      final fresh = ThemeController();
      await fresh.init();
      expect(fresh.mode, ThemeMode.dark);
    });

    test('notifies listeners on change only', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final c = ThemeController();
      await c.init();
      var calls = 0;
      c.addListener(() => calls++);
      await c.setMode(ThemeMode.light);
      await c.setMode(ThemeMode.light);
      expect(calls, 1);
    });

    test('falls back to system on an unknown stored value', () async {
      FlutterSecureStorage.setMockInitialValues({'fusion.theme.v1': 'sepia'});
      final c = ThemeController();
      await c.init();
      expect(c.mode, ThemeMode.system);
    });
  });
}
