import '../../../../core/usecase/usecase.dart';
import '../repositories/app_lock_repository.dart';

/// Whether the lock screen should hold back its automatic prompt (once).
class ConsumeSkipAutoPrompt implements UseCase<bool, NoParams> {
  const ConsumeSkipAutoPrompt(this._appLock);

  final AppLockRepository _appLock;

  @override
  bool call([NoParams _ = const NoParams()]) =>
      _appLock.consumeSkipAutoPrompt();
}
