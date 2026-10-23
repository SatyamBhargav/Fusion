import '../../../../core/usecase/usecase.dart';
import '../../../app_lock/domain/repositories/app_lock_repository.dart';
import '../repositories/auth_repository.dart';

/// Opens the vault after the PIN or biometrics let the user in.
class UnlockWithAppLock implements UseCase<Future<void>, NoParams> {
  const UnlockWithAppLock(this._auth, this._appLock);

  final AuthRepository _auth;
  final AppLockRepository _appLock;

  @override
  Future<void> call([NoParams _ = const NoParams()]) async {
    await _appLock.clearAfterUnlock();
    _auth.unlock();
  }
}
