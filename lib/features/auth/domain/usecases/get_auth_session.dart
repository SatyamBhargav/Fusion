import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class GetAuthSession implements UseCase<AuthSession, NoParams> {
  const GetAuthSession(this._auth);

  final AuthRepository _auth;

  @override
  AuthSession call([NoParams _ = const NoParams()]) => _auth.current;
}
