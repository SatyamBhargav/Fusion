import '../../../../core/usecase/usecase.dart';
import '../entities/app_lock_status.dart';
import '../repositories/app_lock_repository.dart';

/// Every change to the app lock, from now on.
class WatchAppLockStatus implements UseCase<Stream<AppLockStatus>, NoParams> {
  const WatchAppLockStatus(this._appLock);

  final AppLockRepository _appLock;

  @override
  Stream<AppLockStatus> call([NoParams _ = const NoParams()]) =>
      _appLock.changes;
}
