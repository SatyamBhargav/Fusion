import '../../../../core/usecase/usecase.dart';
import '../repositories/app_lock_repository.dart';

/// Re-checks what the device offers, e.g. after enrolling a fingerprint.
class RefreshBiometrics implements UseCase<Future<void>, NoParams> {
  const RefreshBiometrics(this._appLock);

  final AppLockRepository _appLock;

  @override
  Future<void> call([NoParams _ = const NoParams()]) =>
      _appLock.refreshBiometrics();
}
