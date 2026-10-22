import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// The email the latest reset code was sent for.
class GetPendingResetEmail implements UseCase<String?, NoParams> {
  const GetPendingResetEmail(this._auth);

  final AuthRepository _auth;

  @override
  String? call([NoParams _ = const NoParams()]) => _auth.pendingResetEmail;
}
