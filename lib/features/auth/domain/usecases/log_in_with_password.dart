import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../app_lock/domain/repositories/app_lock_repository.dart';
import '../repositories/auth_repository.dart';

class LogInParams {
  const LogInParams({required this.email, required this.password});

  final String email;
  final String password;
}

/// Opens the vault with the master password. That also clears any PIN
/// strikes, so a locked-out PIN works again.
class LogInWithPassword implements UseCase<Future<Result<void>>, LogInParams> {
  const LogInWithPassword(this._auth, this._appLock);

  final AuthRepository _auth;
  final AppLockRepository _appLock;

  @override
  Future<Result<void>> call(LogInParams p) async {
    final result = await _auth.logIn(p.email, p.password);
    // Only after the login: clearing the fallback first would flip the
    // login screen back to the lock.
    if (result.isOk) await _appLock.clearAfterUnlock();
    return result;
  }
}
