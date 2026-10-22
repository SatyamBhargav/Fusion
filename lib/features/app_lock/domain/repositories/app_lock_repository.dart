import '../entities/app_lock_status.dart';

abstract interface class AppLockRepository {
  AppLockStatus get current;

  /// Every change to [current].
  Stream<AppLockStatus> get changes;

  /// Reads the stored PIN and what the device offers.
  Future<void> init();

  /// Re-checks what the device offers, e.g. after enrolling a fingerprint.
  Future<void> refreshBiometrics();

  /// Throws [ArgumentError] unless [pin] is [AppLockStatus.pinLength] digits.
  Future<void> setPin(String pin);

  /// Checks [pin]. Wrong guesses are counted (and saved) until the PIN is
  /// locked out; then only the master password gets back in.
  Future<bool> verifyPin(String pin);

  Future<void> setBiometric(bool on);

  /// Shows the biometric sheet. False if unavailable, locked out, or the
  /// user cancels.
  Future<bool> tryBiometric(String reason);

  /// Prompts even when biometric unlock is still off — used to confirm it
  /// works before switching it on.
  Future<bool> confirmBiometric(String reason);

  /// After "Lock vault" the lock screen mustn't open the vault again with
  /// the owner's face straight away; the biometric key still works.
  void skipNextAutoPrompt();

  /// Whether the lock screen should hold back its automatic prompt (once).
  bool consumeSkipAutoPrompt();

  void requestMasterPassword();

  void cancelMasterPassword();

  /// Any successful unlock clears the strike count and the fallback.
  Future<void> clearAfterUnlock();

  /// Drops the in-memory PIN state once storage has been wiped. Never writes.
  void forget();
}
