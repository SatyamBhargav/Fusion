import '../../domain/entities/vault_item.dart';

/// JSON shape of one item in the stored vault (`fusion.vault.v1`).
abstract final class VaultItemModel {
  static Map<String, dynamic> toJson(VaultItem e) => {
    'id': e.id,
    'name': e.name,
    'website': e.website,
    'username': e.username,
    'password': e.password,
    'note': e.note,
    'favourite': e.favourite,
    'kind': e.kind.name,
    'provider': e.provider,
    'updatedAt': e.updatedAt.toIso8601String(),
  };

  static VaultItem fromJson(Map<String, dynamic> j) {
    return VaultItem(
      id: j['id'] as String,
      name: (j['name'] ?? '') as String,
      website: (j['website'] ?? '') as String,
      username: (j['username'] ?? '') as String,
      password: (j['password'] ?? '') as String,
      note: (j['note'] ?? '') as String,
      favourite: (j['favourite'] ?? false) as bool,
      kind: j['kind'] == 'social' ? LoginKind.social : LoginKind.password,
      provider: (j['provider'] ?? 'google') as String,
      updatedAt:
          DateTime.tryParse((j['updatedAt'] ?? '') as String) ?? DateTime.now(),
    );
  }
}
