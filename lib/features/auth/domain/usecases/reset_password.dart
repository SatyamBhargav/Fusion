import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordParams {
  const ResetPasswordParams({required this.code, required this.newPassword});

  final String code;
  final String newPassword;
}

class ResetPassword
    implements UseCase<Future<Result<void>>, ResetPasswordParams> {
  const ResetPassword(this._auth);

  final AuthRepository _auth;

  @override
  Future<Result<void>> call(ResetPasswordParams p) =>
      _auth.resetPassword(p.code, p.newPassword);
}
