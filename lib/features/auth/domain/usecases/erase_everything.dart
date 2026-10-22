import '../../../../core/usecase/usecase.dart';
import '../../../app_lock/domain/repositories/app_lock_repository.dart';
import '../../../vault/domain/repositories/vault_repository.dart';
import '../repositories/auth_repository.dart';

/// Deletes the account, the PIN and every saved login from this device.
class EraseEverything implements UseCase<Future<void>, NoParams> {
  const EraseEverything(this._auth, this._appLock, this._vault);

  final AuthRepository _auth;
  final AppLockRepository _appLock;
  final VaultRepository _vault;

  @override
  Future<void> call([NoParams _ = const NoParams()]) async {
    await _vault.clear();
    // Wipes all storage; the app moves to the welcome screen.
    await _auth.wipe();
    _appLock.forget();
    _vault.forget();
  }
}
