import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Reads the stored account.
class InitAuth implements UseCase<Future<void>, NoParams> {
  const InitAuth(this._auth);

  final AuthRepository _auth;

  @override
  Future<void> call([NoParams _ = const NoParams()]) => _auth.init();
}
