import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/effects.dart';
import '../../../auth/domain/usecases/unlock_with_app_lock.dart';
import '../../../auth/domain/usecases/use_master_password_instead.dart';
import '../../domain/entities/app_lock_status.dart';
import '../../domain/usecases/consume_skip_auto_prompt.dart';
import '../../domain/usecases/get_app_lock_status.dart';
import '../../domain/usecases/try_biometric.dart';
import '../../domain/usecases/verify_pin.dart';

const lockedOutMessage = 'Too many attempts. Use your master password.';

String wrongPinMessage(AppLockStatus s) {
  if (s.pinLockedOut) return lockedOutMessage;
  final left = s.attemptsLeft;
  return 'Wrong PIN · $left ${left == 1 ? 'try' : 'tries'} left';
}

class LockState extends Equatable {
  const LockState({
    this.entered = '',
    this.busy = false,
    this.done = false,
    this.error,
  });

  /// Digits typed so far.
  final String entered;
  final bool busy;

  /// Unlocked or handed over to the master password; ignores further input.
  final bool done;
  final String? error;

  LockState copyWith({
    String? entered,
    bool? busy,
    bool? done,
    String? Function()? error,
  }) => LockState(
    entered: entered ?? this.entered,
    busy: busy ?? this.busy,
    done: done ?? this.done,
    error: error != null ? error() : this.error,
  );

  @override
  List<Object?> get props => [entered, busy, done, error];
}

enum LockEffect {
  wrongPin,

  /// Unlocked over the screen the user was on; the lock should go away.
  resumeUnlocked,
}

/// Unlocks the vault with the Fusion PIN or biometrics.
///
/// On launch ([resume] false) it opens the vault. On return to the app it
/// sits over whatever the user was doing and just reports that it unlocked.
class LockCubit extends Cubit<LockState> with Effects<LockState, LockEffect> {
  LockCubit({
    required this.resume,
    required GetAppLockStatus getStatus,
    required VerifyPin verifyPin,
    required TryBiometric tryBiometric,
    required ConsumeSkipAutoPrompt consumeSkipAutoPrompt,
    required UnlockWithAppLock unlockWithAppLock,
    required UseMasterPasswordInstead useMasterPassword,
  }) : _getStatus = getStatus,
       _verifyPin = verifyPin,
       _tryBiometric = tryBiometric,
       _consumeSkip = consumeSkipAutoPrompt,
       _unlock = unlockWithAppLock,
       _useMasterPassword = useMasterPassword,
       super(
         LockState(error: getStatus().pinLockedOut ? lockedOutMessage : null),
       );

  final bool resume;
  final GetAppLockStatus _getStatus;
  final VerifyPin _verifyPin;
  final TryBiometric _tryBiometric;
  final ConsumeSkipAutoPrompt _consumeSkip;
  final UnlockWithAppLock _unlock;
  final UseMasterPasswordInstead _useMasterPassword;

  /// Whether to show the biometric sheet as soon as the app is in front.
  /// Call once: it uses up a "Lock vault" request to hold it back.
  bool shouldAutoPrompt() {
    if (_consumeSkip()) return false;
    final s = _getStatus();
    return s.canUseBiometric && !s.pinLockedOut;
  }

  Future<void> _unlocked() async {
    if (state.done) return;
    emit(state.copyWith(done: true));
    if (resume) {
      effect(LockEffect.resumeUnlocked);
    } else {
      await _unlock();
    }
  }

  Future<void> biometric() async {
    if (state.busy || state.done) return;
    final ok = await _tryBiometric('Unlock your Fusion vault');
    if (ok && !isClosed) await _unlocked();
  }

  void digit(String d) {
    if (state.busy ||
        state.done ||
        state.entered.length >= AppLockStatus.pinLength) {
      return;
    }
    final entered = state.entered + d;
    emit(state.copyWith(entered: entered, error: () => null));
    if (entered.length == AppLockStatus.pinLength) _check(entered);
  }

  void backspace() {
    if (state.busy || state.entered.isEmpty) return;
    emit(
      state.copyWith(
        entered: state.entered.substring(0, state.entered.length - 1),
      ),
    );
  }

  Future<void> _check(String pin) async {
    emit(state.copyWith(busy: true));
    final ok = await _verifyPin(pin);
    if (isClosed) return;
    if (ok) {
      await _unlocked();
      return;
    }
    effect(LockEffect.wrongPin);
    emit(
      state.copyWith(
        busy: false,
        entered: '',
        error: () => wrongPinMessage(_getStatus()),
      ),
    );
  }

  void useMasterPassword() {
    if (state.done) return;
    emit(state.copyWith(done: true));
    _useMasterPassword();
  }
}
