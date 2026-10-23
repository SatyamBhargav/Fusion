import 'dart:convert';

/// Ada Lovelace (ada@x.io). With `fastHash` her master password is `pw`.
final accountSeed = jsonEncode({
  'name': 'Ada Lovelace',
  'email': 'ada@x.io',
  'salt': 's',
  'hash': 's|pw',
});

/// PIN 123456 under `fastHash`.
String pinSeed({bool biometric = false, int failed = 0}) => jsonEncode({
  'salt': 's',
  'hash': 's|123456',
  'biometric': biometric,
  'failed': failed,
});

Map<String, Object?> vaultItemJson({
  required String id,
  required String name,
  String website = '',
  String username = '',
  String password = 'pw-123456',
  bool favourite = false,
}) => {
  'id': id,
  'name': name,
  'website': website,
  'username': username,
  'password': password,
  'note': '',
  'favourite': favourite,
  'kind': 'password',
  'provider': 'google',
  'updatedAt': '2026-01-01T00:00:00.000',
};
