import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/storage/secure_storage.dart';
import 'vault_item.dart';

class VaultStore extends ChangeNotifier {
  VaultStore({FlutterSecureStorage? storage})
    : _storage = storage ?? fusionStorage;

  static const _key = 'fusion.vault.v1';
  final FlutterSecureStorage _storage;
  final List<VaultItem> _items = [];
  bool _loaded = false;

  /// Set when stored data couldn't be read; we then refuse to overwrite it.
  bool _readFailed = false;
  bool get readFailed => _readFailed;

  bool get loaded => _loaded;

  List<VaultItem> get items {
    final list = [..._items];
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  List<VaultItem> get favourites => items.where((e) => e.favourite).toList();

  VaultItem? byId(String id) {
    for (final e in _items) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await _storage.read(key: _key);
      _items.clear();
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _items.addAll(
          list.map(
            (e) => VaultItem.fromJson(Map<String, dynamic>.from(e as Map)),
          ),
        );
      }
      _readFailed = false;
    } catch (_) {
      _items.clear();
      _readFailed = true;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_readFailed) {
      throw StateError(
        'Vault storage could not be read; refusing to overwrite it.',
      );
    }
    await _storage.write(
      key: _key,
      value: jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }

  /// Applies [change] optimistically, persists, and rolls back on failure.
  Future<void> _commit(
    void Function() change, {
    bool rethrowError = true,
  }) async {
    final before = List<VaultItem>.of(_items);
    change();
    notifyListeners();
    try {
      await _persist();
    } catch (_) {
      _items
        ..clear()
        ..addAll(before);
      notifyListeners();
      if (rethrowError) rethrow;
    }
  }

  Future<void> add(VaultItem item) => _commit(() => _items.add(item));

  Future<void> update(VaultItem item) => _commit(() {
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i < 0) {
      _items.add(item);
    } else {
      _items[i] = item;
    }
  });

  Future<void> delete(String id) =>
      _commit(() => _items.removeWhere((e) => e.id == id), rethrowError: false);

  Future<void> toggleFavourite(String id) => _commit(() {
    final i = _items.indexWhere((e) => e.id == id);
    if (i >= 0) {
      _items[i] = _items[i].copyWith(favourite: !_items[i].favourite);
    }
  }, rethrowError: false);

  /// Forget the decrypted vault in memory (used when locking).
  void reset() {
    _items.clear();
    _loaded = false;
    _readFailed = false;
    notifyListeners();
  }

  Future<void> clear() async {
    _items.clear();
    _readFailed = false;
    notifyListeners();
    await _storage.delete(key: _key);
  }
}
