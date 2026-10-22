import 'dart:async';

import '../../domain/entities/vault_item.dart';
import '../../domain/entities/vault_snapshot.dart';
import '../../domain/repositories/vault_repository.dart';
import '../datasources/vault_local_data_source.dart';

class VaultRepositoryImpl implements VaultRepository {
  VaultRepositoryImpl(this._local);

  final VaultLocalDataSource _local;
  final _changes = StreamController<VaultSnapshot>.broadcast();

  /// Stored order, kept so saving doesn't reshuffle the file.
  final List<VaultItem> _items = [];
  VaultSnapshot _snapshot = VaultSnapshot.empty;

  @override
  VaultSnapshot get current => _snapshot;

  @override
  Stream<VaultSnapshot> get changes => _changes.stream;

  void _publish({bool? loaded, bool? readFailed}) {
    _snapshot = VaultSnapshot(
      items: _items,
      loaded: loaded ?? _snapshot.loaded,
      readFailed: readFailed ?? _snapshot.readFailed,
    );
    _changes.add(_snapshot);
  }

  @override
  Future<void> load() async {
    if (_snapshot.loaded) return;
    var failed = false;
    try {
      final stored = await _local.read();
      _items
        ..clear()
        ..addAll(stored);
    } catch (_) {
      _items.clear();
      failed = true;
    }
    _publish(loaded: true, readFailed: failed);
  }

  Future<void> _persist() async {
    if (_snapshot.readFailed) {
      throw StateError(
        'Vault storage could not be read; refusing to overwrite it.',
      );
    }
    await _local.write(_items);
  }

  /// Applies [change] optimistically, persists, and rolls back on failure.
  Future<void> _commit(
    void Function() change, {
    bool rethrowError = true,
  }) async {
    final before = List<VaultItem>.of(_items);
    change();
    _publish();
    try {
      await _persist();
    } catch (_) {
      _items
        ..clear()
        ..addAll(before);
      _publish();
      if (rethrowError) rethrow;
    }
  }

  @override
  Future<void> add(VaultItem item) => _commit(() => _items.add(item));

  @override
  Future<void> update(VaultItem item) => _commit(() {
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i < 0) {
      _items.add(item);
    } else {
      _items[i] = item;
    }
  });

  @override
  Future<void> delete(String id) =>
      _commit(() => _items.removeWhere((e) => e.id == id), rethrowError: false);

  @override
  Future<void> toggleFavourite(String id) => _commit(() {
    final i = _items.indexWhere((e) => e.id == id);
    if (i >= 0) {
      _items[i] = _items[i].copyWith(favourite: !_items[i].favourite);
    }
  }, rethrowError: false);

  @override
  void forget() {
    _items.clear();
    _publish(loaded: false, readFailed: false);
  }

  @override
  Future<void> clear() async {
    _items.clear();
    _publish(readFailed: false);
    await _local.delete();
  }
}
