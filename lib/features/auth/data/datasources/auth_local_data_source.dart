import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/storage/secure_storage.dart';
import '../models/account_model.dart';

abstract interface class AuthLocalDataSource {
  /// Null when nothing is stored. Throws if the stored data is unreadable.
  Future<AccountModel?> read();

  Future<void> write(AccountModel account);

  /// Wipes every Fusion key, not just the account.
  Future<void> deleteAll();
}

class SecureAuthLocalDataSource implements AuthLocalDataSource {
  const SecureAuthLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<AccountModel?> read() async {
    final raw = await _storage.read(key: StorageKeys.account);
    if (raw == null) return null;
    return AccountModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> write(AccountModel account) => _storage.write(
    key: StorageKeys.account,
    value: jsonEncode(account.toJson()),
  );

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}
