import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Every change to the session, from now on.
class WatchAuthSession implements UseCase<Stream<AuthSession>, NoParams> {
  const WatchAuthSession(this._auth);

  final AuthRepository _auth;

  @override
  Stream<AuthSession> call([NoParams _ = const NoParams()]) => _auth.changes;
}
