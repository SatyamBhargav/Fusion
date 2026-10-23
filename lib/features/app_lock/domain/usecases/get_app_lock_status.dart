import '../../../../core/usecase/usecase.dart';
import '../entities/app_lock_status.dart';
import '../repositories/app_lock_repository.dart';

class GetAppLockStatus implements UseCase<AppLockStatus, NoParams> {
  const GetAppLockStatus(this._appLock);

  final AppLockRepository _appLock;

  @override
  AppLockStatus call([NoParams _ = const NoParams()]) => _appLock.current;
}
