import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Creates a reset code for [email] and returns it.
class RequestPasswordReset implements UseCase<Result<String>, String> {
  const RequestPasswordReset(this._auth);

  final AuthRepository _auth;

  @override
  Result<String> call(String email) => _auth.requestReset(email);
}
