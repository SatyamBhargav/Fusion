import '../../../../core/usecase/usecase.dart';
import '../repositories/app_lock_repository.dart';

class SetBiometric implements UseCase<Future<void>, bool> {
  const SetBiometric(this._appLock);

  final AppLockRepository _appLock;

  @override
  Future<void> call(bool on) => _appLock.setBiometric(on);
}
