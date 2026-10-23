import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../app_lock/domain/repositories/app_lock_repository.dart';
import '../repositories/auth_repository.dart';

class SignUpParams {
  const SignUpParams({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;
}

/// Creates the device's account and opens the vault.
class SignUp implements UseCase<Future<Result<void>>, SignUpParams> {
  const SignUp(this._auth, this._appLock);

  final AuthRepository _auth;
  final AppLockRepository _appLock;

  @override
  Future<Result<void>> call(SignUpParams p) async {
    final result = await _auth.signUp(
      name: p.name,
      email: p.email,
      password: p.password,
    );
    if (result.isOk) await _appLock.clearAfterUnlock();
    return result;
  }
}
