import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/vault_item.dart';
import '../models/vault_item_model.dart';

abstract interface class VaultLocalDataSource {
  /// Empty when nothing is stored. Throws if the stored data is unreadable.
  Future<List<VaultItem>> read();

  Future<void> write(List<VaultItem> items);

  Future<void> delete();
}

class SecureVaultLocalDataSource implements VaultLocalDataSource {
  const SecureVaultLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<List<VaultItem>> read() async {
    final raw = await _storage.read(key: StorageKeys.vault);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final e in list)
        VaultItemModel.fromJson(Map<String, dynamic>.from(e as Map)),
    ];
  }

  @override
  Future<void> write(List<VaultItem> items) => _storage.write(
    key: StorageKeys.vault,
    value: jsonEncode(items.map(VaultItemModel.toJson).toList()),
  );

  @override
  Future<void> delete() => _storage.delete(key: StorageKeys.vault);
}
