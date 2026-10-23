import '../../domain/entities/account.dart';

/// The stored account record (`fusion.account.v1`). The password is only
/// ever kept as a salted, stretched hash.
class AccountModel {
  const AccountModel({
    required this.name,
    required this.email,
    required this.salt,
    required this.hash,
  });

  factory AccountModel.fromJson(Map<String, dynamic> m) => AccountModel(
    name: m['name'] as String?,
    email: m['email'] as String?,
    salt: m['salt'] as String?,
    hash: m['hash'] as String?,
  );

  final String? name;
  final String? email;
  final String? salt;
  final String? hash;

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'salt': salt,
    'hash': hash,
  };

  Account toEntity() => Account(name: name, email: email);
}
