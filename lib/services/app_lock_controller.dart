import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_service.dart';
import 'biometric_auth.dart';
import 'hashing.dart';
import 'storage.dart';

typedef PinHasher = Future<String> Function(String salt, String pin);

/// The app lock: a 6-digit Fusion PIN (stored only as a salted, stretched
/// hash), plus optional biometric unlock on top of it. After a master
/// password login it is what opens the vault on every launch and return.
class AppLockController extends ChangeNotifier {
  AppLockController({
    required AuthService auth,
    BiometricAuth? biometrics,
    FlutterSecureStorage? storage,
    PinHasher? hasher,
  }) : _auth = auth,
       _biometrics = biometrics ?? LocalBiometricAuth(),
       _storage = storage ?? fusionStorage,
       _hasher = hasher ?? hashInBackground {
    _wasLoggedIn = auth.loggedIn;
    auth.addListener(_onAuthChanged);
  }

  static const pinLength = 6;
  static const maxAttempts = 5;
  static const _key = 'fusion.applock.v1';

  final AuthService _auth;
  final BiometricAuth _biometrics;
  final FlutterSecureStorage _storage;
  final PinHasher _hasher;

  String? _salt;
  String? _hash;
  bool _biometric = false;
  int _failed = 0;
  BiometricKind _kind = BiometricKind.none;
  bool _masterPasswordRequested = false;
  bool _skipAutoPrompt = false;
  bool _wasLoggedIn = false;

  bool get hasPin => _hash != null;
  bool get biometricEnabled => _biometric;
  BiometricKind get biometricKind => _kind;
  bool get canUseBiometric => _biometric && _kind != BiometricKind.none;
  int get failedAttempts => _failed;
  int get attemptsLeft => (maxAttempts - _failed).clamp(0, maxAttempts);
  bool get pinLockedOut => _failed >= maxAttempts;
  bool get masterPasswordRequested => _masterPasswordRequested;

  Future<void> init() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        _salt = m['salt'] as String?;
        _hash = m['hash'] as String?;
        _biometric = m['biometric'] as bool? ?? false;
        _failed = m['failed'] as int? ?? 0;
        if (_salt == null) _hash = null;
      }
    } catch (_) {
      // Unreadable: treat as no PIN; the next login sets a new one.
      _salt = null;
      _hash = null;
    }
    _kind = await _biometrics.available();
    notifyListeners();
  }

  /// Re-checks what the device offers, e.g. after enrolling a fingerprint.
  Future<void> refreshBiometrics() async {
    final kind = await _biometrics.available();
    if (kind == _kind) return;
    _kind = kind;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      await _storage.write(
        key: _key,
        value: jsonEncode({
          'salt': _salt,
          'hash': _hash,
          'biometric': _biometric,
          'failed': _failed,
        }),
      );
    } catch (_) {
      // Keep the in-memory state even if it can't be saved.
    }
  }

  static bool isValidPin(String pin) =>
      pin.length == pinLength && RegExp(r'^\d+$').hasMatch(pin);

  Future<void> setPin(String pin) async {
    if (!isValidPin(pin)) {
      throw ArgumentError.value(pin, 'pin', 'must be $pinLength digits');
    }
    final salt = newSalt();
    final hash = await _hasher(salt, pin);
    _salt = salt;
    _hash = hash;
    _failed = 0;
    await _save();
    notifyListeners();
  }

  /// Checks [pin]. Wrong guesses are counted (and saved) until the PIN is
  /// locked out; then only the master password gets back in.
  Future<bool> verifyPin(String pin) async {
    final salt = _salt;
    final expected = _hash;
    if (salt == null || expected == null || pinLockedOut) return false;
    final ok = constantTimeEquals(await _hasher(salt, pin), expected);
    _failed = ok ? 0 : _failed + 1;
    await _save();
    notifyListeners();
    return ok;
  }

  Future<void> setBiometric(bool on) async {
    if (on == _biometric) return;
    _biometric = on;
    notifyListeners();
    await _save();
  }

  /// Shows the biometric sheet. False if it's off, unavailable, locked out,
  /// or the user cancels.
  Future<bool> tryBiometric(String reason) async {
    if (_kind == BiometricKind.none || pinLockedOut) return false;
    return _biometrics.authenticate(reason);
  }

  /// Prompts even when biometric unlock is still off — used to confirm it
  /// works before switching it on.
  Future<bool> confirmBiometric(String reason) async {
    if (_kind == BiometricKind.none) return false;
    return _biometrics.authenticate(reason);
  }

  /// After "Lock vault" the lock screen mustn't open the vault again with
  /// the owner's face straight away; the biometric key still works.
  void skipNextAutoPrompt() => _skipAutoPrompt = true;

  /// Whether the lock screen should hold back its automatic prompt (once).
  bool consumeSkipAutoPrompt() {
    final skip = _skipAutoPrompt;
    _skipAutoPrompt = false;
    return skip;
  }

  void requestMasterPassword() {
    if (_masterPasswordRequested) return;
    _masterPasswordRequested = true;
    notifyListeners();
  }

  void cancelMasterPassword() {
    if (!_masterPasswordRequested) return;
    _masterPasswordRequested = false;
    notifyListeners();
  }

  void _onAuthChanged() {
    final loggedIn = _auth.loggedIn;
    if (loggedIn && !_wasLoggedIn) {
      // Any successful unlock clears the strike count and the fallback.
      final changed = _failed != 0 || _masterPasswordRequested;
      _masterPasswordRequested = false;
      if (_failed != 0) {
        _failed = 0;
        _save();
      }
      if (changed) notifyListeners();
    }
    _wasLoggedIn = loggedIn;

    if (_auth.ready && !_auth.hasAccount && (hasPin || _biometric)) {
      // Vault erased: storage is already wiped, forget the in-memory copy.
      _salt = null;
      _hash = null;
      _biometric = false;
      _failed = 0;
      _masterPasswordRequested = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
