import '../entities/vault_item.dart';
import '../entities/vault_snapshot.dart';

abstract interface class VaultRepository {
  VaultSnapshot get current;

  /// Every change to [current].
  Stream<VaultSnapshot> get changes;

  /// Reads the stored vault once; later calls do nothing until [forget].
  Future<void> load();

  /// Adds [item]; rolls back and throws if it can't be saved.
  Future<void> add(VaultItem item);

  /// Replaces the item with [item]'s id; rolls back and throws if it can't
  /// be saved.
  Future<void> update(VaultItem item);

  /// Removes an item. Rolls back quietly if it can't be saved.
  Future<void> delete(String id);

  /// Rolls back quietly if it can't be saved.
  Future<void> toggleFavourite(String id);

  /// Drops the decrypted vault from memory (used when locking).
  void forget();

  /// Deletes the stored vault.
  Future<void> clear();
}
