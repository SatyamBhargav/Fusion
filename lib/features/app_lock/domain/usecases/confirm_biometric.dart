import '../../../../core/usecase/usecase.dart';
import '../repositories/app_lock_repository.dart';

/// Prompts even when biometric unlock is off, to check it works first.
class ConfirmBiometric implements UseCase<Future<bool>, String> {
  const ConfirmBiometric(this._appLock);

  final AppLockRepository _appLock;

  @override
  Future<bool> call(String reason) => _appLock.confirmBiometric(reason);
}
