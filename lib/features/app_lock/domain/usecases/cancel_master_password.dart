import '../../../../core/usecase/usecase.dart';
import '../repositories/app_lock_repository.dart';

/// Goes back from the master password login to the PIN lock.
class CancelMasterPassword implements UseCase<void, NoParams> {
  const CancelMasterPassword(this._appLock);

  final AppLockRepository _appLock;

  @override
  void call([NoParams _ = const NoParams()]) => _appLock.cancelMasterPassword();
}
