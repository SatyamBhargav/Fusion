import 'package:flutter/painting.dart';

import '../domain/entities/vault_item.dart';

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

extension VaultItemSubtitle on VaultItem {
  /// The username, or which provider a social sign-in goes through.
  String get subtitle =>
      isSocial ? 'via ${providerById(provider).name}' : username;
}
