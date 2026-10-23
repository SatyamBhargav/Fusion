import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/effects.dart';
import '../../../app_lock/domain/usecases/confirm_biometric.dart';
import '../../../app_lock/domain/usecases/set_biometric.dart';
import '../../../auth/domain/usecases/erase_everything.dart';
import '../../../auth/domain/usecases/lock_vault.dart';

sealed class SettingsEffect {
  const SettingsEffect();
}

/// The biometric check before turning it on failed.
final class BiometricNotVerified extends SettingsEffect {
  const BiometricNotVerified(this.label);

  final String label;
}

/// Settings actions. What they show comes from the global blocs, so the
/// state carries nothing.
class SettingsCubit extends Cubit<void> with Effects<void, SettingsEffect> {
  SettingsCubit({
    required SetBiometric setBiometric,
    required ConfirmBiometric confirmBiometric,
    required LockVault lockVault,
    required EraseEverything eraseEverything,
  }) : _setBiometric = setBiometric,
       _confirmBiometric = confirmBiometric,
       _lockVault = lockVault,
       _erase = eraseEverything,
       super(null);

  final SetBiometric _setBiometric;
  final ConfirmBiometric _confirmBiometric;
  final LockVault _lockVault;
  final EraseEverything _erase;

  /// Turning it on asks for biometrics first. [label] is what the platform
  /// calls it, e.g. "Face ID".
  Future<void> setBiometric(bool on, String label) async {
    if (!on) return _setBiometric(false);
    final ok = await _confirmBiometric('Turn on $label for Fusion');
    if (ok) {
      await _setBiometric(true);
    } else {
      effect(BiometricNotVerified(label));
    }
  }

  void lockVault() => _lockVault();

  Future<void> eraseEverything() => _erase();
}
