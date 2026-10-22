import '../../../../core/usecase/usecase.dart';
import '../repositories/app_lock_repository.dart';

/// Unlocks with biometrics; refused while the PIN is locked out.
class TryBiometric implements UseCase<Future<bool>, String> {
  const TryBiometric(this._appLock);

  final AppLockRepository _appLock;

  @override
  Future<bool> call(String reason) => _appLock.tryBiometric(reason);
}
