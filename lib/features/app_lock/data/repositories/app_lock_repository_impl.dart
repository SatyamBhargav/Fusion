import 'dart:async';

import '../../../../core/security/hashing.dart';
import '../../domain/entities/app_lock_status.dart';
import '../../domain/entities/biometric_kind.dart';
import '../../domain/repositories/app_lock_repository.dart';
import '../datasources/app_lock_local_data_source.dart';
import '../datasources/biometric_data_source.dart';
import '../models/app_lock_model.dart';

class AppLockRepositoryImpl implements AppLockRepository {
  AppLockRepositoryImpl(
    this._local, {
    required BiometricAuth biometrics,
    required PasswordHasher hasher,
  }) : _biometrics = biometrics,
       _hasher = hasher;

  final AppLockLocalDataSource _local;
  final BiometricAuth _biometrics;
  final PasswordHasher _hasher;
  final _changes = StreamController<AppLockStatus>.broadcast();

  String? _salt;
  String? _hash;
  bool _skipAutoPrompt = false;
  AppLockStatus _status = const AppLockStatus();

  @override
  AppLockStatus get current => _status;

  @override
  Stream<AppLockStatus> get changes => _changes.stream;

  void _set(AppLockStatus next) {
    if (next == _status) return;
    _status = next;
    _changes.add(next);
  }

  @override
  Future<void> init() async {
    var stored = const AppLockModel();
    try {
      stored = await _local.read() ?? stored;
    } catch (_) {
      // Unreadable: treat as no PIN; the next login sets a new one.
    }
    _salt = stored.salt;
    _hash = stored.hash;
    final kind = await _biometrics.available();
    _set(
      _status.copyWith(
        ready: true,
        hasPin: _hash != null,
        biometricEnabled: stored.biometric,
        failed: stored.failed,
        kind: kind,
      ),
    );
  }

  @override
  Future<void> refreshBiometrics() async {
    _set(_status.copyWith(kind: await _biometrics.available()));
  }

  Future<void> _save() async {
    try {
      await _local.write(
        AppLockModel(
          salt: _salt,
          hash: _hash,
          biometric: _status.biometricEnabled,
          failed: _status.failed,
        ),
      );
    } catch (_) {
      // Keep the in-memory state even if it can't be saved.
    }
  }

  @override
  Future<void> setPin(String pin) async {
    if (!AppLockStatus.isValidPin(pin)) {
      throw ArgumentError.value(
        pin,
        'pin',
        'must be ${AppLockStatus.pinLength} digits',
      );
    }
    final salt = newSalt();
    final hash = await _hasher(salt, pin);
    _salt = salt;
    _hash = hash;
    _status = _status.copyWith(hasPin: true, failed: 0);
    await _save();
    _changes.add(_status);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final salt = _salt;
    final expected = _hash;
    if (salt == null || expected == null || _status.pinLockedOut) return false;
    final ok = constantTimeEquals(await _hasher(salt, pin), expected);
    _status = _status.copyWith(failed: ok ? 0 : _status.failed + 1);
    await _save();
    _changes.add(_status);
    return ok;
  }

  @override
  Future<void> setBiometric(bool on) async {
    if (on == _status.biometricEnabled) return;
    _set(_status.copyWith(biometricEnabled: on));
    await _save();
  }

  @override
  Future<bool> tryBiometric(String reason) async {
    if (_status.kind == BiometricKind.none || _status.pinLockedOut) {
      return false;
    }
    return _biometrics.authenticate(reason);
  }

  @override
  Future<bool> confirmBiometric(String reason) async {
    if (_status.kind == BiometricKind.none) return false;
    return _biometrics.authenticate(reason);
  }

  @override
  void skipNextAutoPrompt() => _skipAutoPrompt = true;

  @override
  bool consumeSkipAutoPrompt() {
    final skip = _skipAutoPrompt;
    _skipAutoPrompt = false;
    return skip;
  }

  @override
  void requestMasterPassword() =>
      _set(_status.copyWith(masterPasswordRequested: true));

  @override
  void cancelMasterPassword() =>
      _set(_status.copyWith(masterPasswordRequested: false));

  @override
  Future<void> clearAfterUnlock() async {
    final hadStrikes = _status.failed != 0;
    _set(_status.copyWith(failed: 0, masterPasswordRequested: false));
    if (hadStrikes) await _save();
  }

  @override
  void forget() {
    _salt = null;
    _hash = null;
    _skipAutoPrompt = false;
    _set(
      _status.copyWith(
        hasPin: false,
        biometricEnabled: false,
        failed: 0,
        masterPasswordRequested: false,
      ),
    );
  }
}
