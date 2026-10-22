import 'package:flutter/painting.dart';

enum LoginKind { password, social }

class SocialProvider {
  const SocialProvider({
    required this.id,
    required this.name,
    required this.mono,
    required this.tile,
    required this.ink,
  });

  final String id;
  final String name;
  final String mono;
  final Color tile;
  final Color ink;
}

/// Monogram tiles stand in for brand logos — swap in official icons
/// (following each provider's brand guidelines) before shipping.
const socialProviders = <SocialProvider>[
  SocialProvider(
    id: 'google',
    name: 'Google',
    mono: 'G',
    tile: Color(0xFFFFE6DA),
    ink: Color(0xFF8A3A17),
  ),
  SocialProvider(
    id: 'apple',
    name: 'Apple',
    mono: 'A',
    tile: Color(0xFF16142B),
    ink: Color(0xFFFFFFFF),
  ),
  SocialProvider(
    id: 'facebook',
    name: 'Facebook',
    mono: 'f',
    tile: Color(0xFFDCEFFF),
    ink: Color(0xFF1D4F7A),
  ),
  SocialProvider(
    id: 'x',
    name: 'X',
    mono: 'X',
    tile: Color(0xFFE9E7F2),
    ink: Color(0xFF16142B),
  ),
  SocialProvider(
    id: 'github',
    name: 'GitHub',
    mono: 'GH',
    tile: Color(0xFFDDF5EA),
    ink: Color(0xFF1F5E43),
  ),
  SocialProvider(
    id: 'microsoft',
    name: 'Microsoft',
    mono: 'M',
    tile: Color(0xFFE7E3FF),
    ink: Color(0xFF3B2BC4),
  ),
];

SocialProvider providerById(String? id) => socialProviders.firstWhere(
  (p) => p.id == id,
  orElse: () => socialProviders.first,
);

class VaultItem {
  const VaultItem({
    required this.id,
    required this.name,
    required this.website,
    required this.username,
    required this.password,
    required this.note,
    required this.favourite,
    required this.kind,
    required this.provider,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String website;

  /// Username / email for password logins, or the account used for social sign-in.
  final String username;
  final String password;
  final String note;
  final bool favourite;
  final LoginKind kind;
  final String provider;
  final DateTime updatedAt;

  bool get isSocial => kind == LoginKind.social;

  String get subtitle =>
      isSocial ? 'via ${providerById(provider).name}' : username;

  String get host {
    var s = website.trim();
    s = s.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
    if (s.endsWith('/')) s = s.substring(0, s.length - 1);
    return s;
  }

  VaultItem copyWith({
    String? name,
    String? website,
    String? username,
    String? password,
    String? note,
    bool? favourite,
    LoginKind? kind,
    String? provider,
    DateTime? updatedAt,
  }) {
    return VaultItem(
      id: id,
      name: name ?? this.name,
      website: website ?? this.website,
      username: username ?? this.username,
      password: password ?? this.password,
      note: note ?? this.note,
      favourite: favourite ?? this.favourite,
      kind: kind ?? this.kind,
      provider: provider ?? this.provider,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'website': website,
    'username': username,
    'password': password,
    'note': note,
    'favourite': favourite,
    'kind': kind.name,
    'provider': provider,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory VaultItem.fromJson(Map<String, dynamic> j) {
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
