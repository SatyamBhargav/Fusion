import 'package:equatable/equatable.dart';

import 'vault_item.dart';

/// The decrypted vault as currently held in memory.
class VaultSnapshot extends Equatable {
  VaultSnapshot({
    List<VaultItem> items = const [],
    this.loaded = false,
    this.readFailed = false,
  }) : items = List.unmodifiable(
         [...items]..sort(
           (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
         ),
       );

  static final empty = VaultSnapshot();

  /// Sorted by name.
  final List<VaultItem> items;
  final bool loaded;

  /// Stored data couldn't be read; the vault refuses to overwrite it.
  final bool readFailed;

  List<VaultItem> get favourites => items.where((e) => e.favourite).toList();

  VaultItem? byId(String id) {
    for (final e in items) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  List<Object?> get props => [items, loaded, readFailed];
}
