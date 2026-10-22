import '../../../../core/usecase/usecase.dart';
import '../../../app_lock/domain/repositories/app_lock_repository.dart';
import '../../../vault/domain/repositories/vault_repository.dart';
import '../repositories/auth_repository.dart';

/// "Lock vault": forgets the decrypted vault and shows the lock, which
/// then waits for the owner instead of prompting for biometrics at once.
class LockVault implements UseCase<void, NoParams> {
  const LockVault(this._auth, this._appLock, this._vault);

  final AuthRepository _auth;
  final AppLockRepository _appLock;
  final VaultRepository _vault;

  @override
  void call([NoParams _ = const NoParams()]) {
    _vault.forget();
    _appLock.skipNextAutoPrompt();
    _auth.logOut();
  }
}
