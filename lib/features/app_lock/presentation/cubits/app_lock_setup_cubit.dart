import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/effects.dart';
import '../../../auth/domain/usecases/get_auth_session.dart';
import '../../domain/entities/app_lock_status.dart';
import '../../domain/entities/biometric_kind.dart';
import '../../domain/usecases/confirm_biometric.dart';
import '../../domain/usecases/get_app_lock_status.dart';
import '../../domain/usecases/set_biometric.dart';
import '../../domain/usecases/set_pin.dart';
import '../../domain/usecases/verify_pin.dart';
import 'lock_cubit.dart';

enum SetupStep { current, create, confirm, biometric }

class AppLockSetupState extends Equatable {
  const AppLockSetupState({
    required this.step,
    this.entered = '',
    this.first = '',
    this.busy = false,
    this.error,
  });

  final SetupStep step;

  /// Digits typed on this step.
  final String entered;

  /// The new PIN from the create step, waiting to be confirmed.
  final String first;
  final bool busy;
  final String? error;

  AppLockSetupState copyWith({
    SetupStep? step,
    String? entered,
    String? first,
    bool? busy,
    String? Function()? error,
  }) => AppLockSetupState(
    step: step ?? this.step,
    entered: entered ?? this.entered,
    first: first ?? this.first,
    busy: busy ?? this.busy,
    error: error != null ? error() : this.error,
  );

  @override
  List<Object?> get props => [step, entered, first, busy, error];
}

enum AppLockSetupEffect {
  failed,

  /// The PIN was changed from Settings; the screen should close.
  changed,
}

/// Sets the Fusion PIN. Right after the first login this is mandatory and
/// ends with an optional offer to turn on biometrics. With [change] it is
/// opened from Settings and checks the current PIN first.
class AppLockSetupCubit extends Cubit<AppLockSetupState>
    with Effects<AppLockSetupState, AppLockSetupEffect> {
  AppLockSetupCubit({
    required this.change,
    required GetAuthSession getSession,
    required GetAppLockStatus getStatus,
    required VerifyPin verifyPin,
    required SetPin setPin,
    required SetBiometric setBiometric,
    required ConfirmBiometric confirmBiometric,
  }) : _getStatus = getStatus,
       _verifyPin = verifyPin,
       _setPin = setPin,
       _setBiometric = setBiometric,
       _confirmBiometric = confirmBiometric,
       super(
         AppLockSetupState(
           // A session opened with the master password may replace a
           // forgotten PIN.
           step: change && !getSession().passwordVerified
               ? SetupStep.current
               : SetupStep.create,
         ),
       );

  final bool change;
  final GetAppLockStatus _getStatus;
  final VerifyPin _verifyPin;
  final SetPin _setPin;
  final SetBiometric _setBiometric;
  final ConfirmBiometric _confirmBiometric;

  void _fail(String message, {SetupStep? step, String? first}) {
    effect(AppLockSetupEffect.failed);
    emit(
      state.copyWith(
        step: step,
        first: first,
        busy: false,
        entered: '',
        error: () => message,
      ),
    );
  }

  void digit(String d) {
    if (state.busy || state.entered.length >= AppLockStatus.pinLength) return;
    final entered = state.entered + d;
    emit(state.copyWith(entered: entered, error: () => null));
    if (entered.length == AppLockStatus.pinLength) _submit(entered);
  }

  void backspace() {
    if (state.busy || state.entered.isEmpty) return;
    emit(
      state.copyWith(
        entered: state.entered.substring(0, state.entered.length - 1),
      ),
    );
  }

  Future<void> _submit(String pin) async {
    switch (state.step) {
      case SetupStep.current:
        emit(state.copyWith(busy: true));
        final ok = await _verifyPin(pin);
        if (isClosed) return;
        if (!ok) {
          _fail(wrongPinMessage(_getStatus()));
          return;
        }
        emit(state.copyWith(busy: false, entered: '', step: SetupStep.create));
      case SetupStep.create:
        emit(state.copyWith(first: pin, entered: '', step: SetupStep.confirm));
      case SetupStep.confirm:
        if (pin != state.first) {
          _fail(
            'PINs didn’t match. Try again.',
            step: SetupStep.create,
            first: '',
          );
          return;
        }
        if (!change && _getStatus().kind != BiometricKind.none) {
          emit(state.copyWith(entered: '', step: SetupStep.biometric));
          return;
        }
        await _finish(biometric: false);
      case SetupStep.biometric:
        break;
    }
  }

  /// "Not now" on the biometric offer.
  Future<void> skipBiometric() => _finish(biometric: false);

  /// [label] is what the platform calls it, e.g. "Face ID".
  Future<void> enableBiometric(String label) async {
    emit(state.copyWith(busy: true, error: () => null));
    final ok = await _confirmBiometric('Turn on biometric unlock');
    if (isClosed) return;
    if (!ok) {
      emit(
        state.copyWith(
          busy: false,
          error: () => 'Couldn’t verify $label. Try again.',
        ),
      );
      return;
    }
    await _finish(biometric: true);
  }

  /// Saves the PIN last: once it exists the app moves on to the vault, so
  /// the spinner stays up until then.
  Future<void> _finish({required bool biometric}) async {
    emit(state.copyWith(busy: true));
    if (biometric) await _setBiometric(true);
    await _setPin(state.first);
    if (change && !isClosed) effect(AppLockSetupEffect.changed);
  }
}
