import '../../../../core/usecase/usecase.dart';
import '../../../app_lock/domain/repositories/app_lock_repository.dart';
import '../../../vault/domain/repositories/vault_repository.dart';
import '../repositories/auth_repository.dart';

/// Leaves the PIN lock for the master password login, locking the vault
/// fully if it was open underneath.
class UseMasterPasswordInstead implements UseCase<void, NoParams> {
  const UseMasterPasswordInstead(this._auth, this._appLock, this._vault);

  final AuthRepository _auth;
  final AppLockRepository _appLock;
  final VaultRepository _vault;

  @override
  void call([NoParams _ = const NoParams()]) {
    // Request first, so logging out lands on the login, never briefly on
    // the PIN lock (which would prompt for biometrics).
    _appLock.requestMasterPassword();
    if (!_auth.current.loggedIn) return;
    _vault.forget();
    _auth.logOut();
  }
}
