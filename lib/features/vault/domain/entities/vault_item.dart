import 'package:equatable/equatable.dart';

enum LoginKind { password, social }

/// One saved login: a stored password, or the account used for a social
/// sign-in.
class VaultItem extends Equatable {
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

  /// Social provider id, e.g. `google`.
  final String provider;
  final DateTime updatedAt;

  bool get isSocial => kind == LoginKind.social;

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

  @override
  List<Object?> get props => [
    id,
    name,
    website,
    username,
    password,
    note,
    favourite,
    kind,
    provider,
    updatedAt,
  ];
}
