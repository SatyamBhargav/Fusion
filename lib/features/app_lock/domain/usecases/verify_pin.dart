import '../../../../core/usecase/usecase.dart';
import '../repositories/app_lock_repository.dart';

/// Checks a PIN; wrong guesses count towards the lockout.
class VerifyPin implements UseCase<Future<bool>, String> {
  const VerifyPin(this._appLock);

  final AppLockRepository _appLock;

  @override
  Future<bool> call(String pin) => _appLock.verifyPin(pin);
}
