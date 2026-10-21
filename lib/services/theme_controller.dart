import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'storage.dart';

/// The user's appearance choice: light, dark, or follow the device.
/// Persisted alongside the rest of Fusion's data in secure storage.
class ThemeController extends ChangeNotifier {
  ThemeController({FlutterSecureStorage? storage})
    : _storage = storage ?? fusionStorage;

  static const _key = 'fusion.theme.v1';
  final FlutterSecureStorage _storage;

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> init() async {
    try {
      final raw = await _storage.read(key: _key);
      _mode = ThemeMode.values.firstWhere(
        (m) => m.name == raw,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      // Unreadable storage: follow the device.
      _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await _storage.write(key: _key, value: mode.name);
    } catch (_) {
      // Keep the in-memory choice even if it can't be saved.
    }
  }
}
