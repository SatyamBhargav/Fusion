import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/storage/secure_storage.dart';

abstract interface class ThemeLocalDataSource {
  Future<String?> read();

  Future<void> write(String mode);
}

/// Persisted alongside the rest of Fusion's data in secure storage.
class SecureThemeLocalDataSource implements ThemeLocalDataSource {
  const SecureThemeLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: StorageKeys.theme);

  @override
  Future<void> write(String mode) =>
      _storage.write(key: StorageKeys.theme, value: mode);
}
