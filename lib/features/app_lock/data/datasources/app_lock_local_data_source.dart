import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/storage/secure_storage.dart';
import '../models/app_lock_model.dart';

abstract interface class AppLockLocalDataSource {
  /// Null when nothing is stored. Throws if the stored data is unreadable.
  Future<AppLockModel?> read();

  Future<void> write(AppLockModel model);
}

class SecureAppLockLocalDataSource implements AppLockLocalDataSource {
  const SecureAppLockLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<AppLockModel?> read() async {
    final raw = await _storage.read(key: StorageKeys.appLock);
    if (raw == null) return null;
    return AppLockModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> write(AppLockModel model) => _storage.write(
    key: StorageKeys.appLock,
    value: jsonEncode(model.toJson()),
  );
}
