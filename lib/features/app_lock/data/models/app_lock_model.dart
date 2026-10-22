/// The stored app lock record (`fusion.applock.v1`). The PIN is only ever
/// kept as a salted, stretched hash.
class AppLockModel {
  const AppLockModel({
    this.salt,
    this.hash,
    this.biometric = false,
    this.failed = 0,
  });

  factory AppLockModel.fromJson(Map<String, dynamic> m) {
    final salt = m['salt'] as String?;
    return AppLockModel(
      salt: salt,
      // A hash without its salt can never be checked.
      hash: salt == null ? null : m['hash'] as String?,
      biometric: m['biometric'] as bool? ?? false,
      failed: m['failed'] as int? ?? 0,
    );
  }

  final String? salt;
  final String? hash;
  final bool biometric;
  final int failed;

  Map<String, dynamic> toJson() => {
    'salt': salt,
    'hash': hash,
    'biometric': biometric,
    'failed': failed,
  };
}
