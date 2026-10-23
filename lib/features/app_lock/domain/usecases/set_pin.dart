import '../../../../core/usecase/usecase.dart';
import '../repositories/app_lock_repository.dart';

class SetPin implements UseCase<Future<void>, String> {
  const SetPin(this._appLock);

  final AppLockRepository _appLock;

  @override
  Future<void> call(String pin) => _appLock.setPin(pin);
}
