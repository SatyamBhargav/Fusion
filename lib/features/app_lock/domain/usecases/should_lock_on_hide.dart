import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../repositories/app_lock_repository.dart';

/// Whether leaving the app should lock it: only an open vault with a PIN.
class ShouldLockOnHide implements UseCase<bool, NoParams> {
  const ShouldLockOnHide(this._auth, this._appLock);

  final AuthRepository _auth;
  final AppLockRepository _appLock;

  @override
  bool call([NoParams _ = const NoParams()]) =>
      _auth.current.loggedIn && _appLock.current.hasPin;
}
