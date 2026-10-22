import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';

/// Local-only account: one master password per device. Nothing leaves the
/// device.
abstract interface class AuthRepository {
  AuthSession get current;

  /// Every change to [current].
  Stream<AuthSession> get changes;

  /// Reads the stored account. [current] is not ready until this completes.
  Future<void> init();

  Future<Result<void>> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<Result<void>> logIn(String email, String password);

  /// Creates a 6-digit reset code valid for 10 minutes and returns it. With
  /// no server the app shows the code itself.
  Result<String> requestReset(String email);

  /// The email the latest reset code was sent for.
  String? get pendingResetEmail;

  Future<Result<void>> resetPassword(String code, String newPassword);

  /// Opens the vault after the app lock (PIN or biometrics) let the user in.
  void unlock();

  void logOut();

  /// Erases the account and every stored login on this device.
  Future<void> wipe();
}
