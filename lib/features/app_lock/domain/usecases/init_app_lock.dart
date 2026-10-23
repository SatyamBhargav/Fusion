import '../../../../core/usecase/usecase.dart';
import '../repositories/app_lock_repository.dart';

/// Reads the stored PIN and what the device offers.
class InitAppLock implements UseCase<Future<void>, NoParams> {
  const InitAppLock(this._appLock);

  final AppLockRepository _appLock;

  @override
  Future<void> call([NoParams _ = const NoParams()]) => _appLock.init();
}
