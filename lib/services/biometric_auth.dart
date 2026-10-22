import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricKind { none, face, fingerprint, other }

extension BiometricKindLabel on BiometricKind {
  /// What the platform calls this unlock method, e.g. "Face ID".
  String get label {
    final apple =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    return switch (this) {
      BiometricKind.face => apple ? 'Face ID' : 'face unlock',
      BiometricKind.fingerprint => apple ? 'Touch ID' : 'fingerprint',
      _ => 'biometrics',
    };
  }
}

/// The device's biometric unlock (Face ID, Touch ID, fingerprint…).
/// Behind an interface so tests can swap in a fake.
abstract class BiometricAuth {
  Future<BiometricKind> available();

  /// Shows the system prompt. False when the user fails or cancels, or the
  /// platform can't prompt; never throws.
  Future<bool> authenticate(String reason);
}

class LocalBiometricAuth implements BiometricAuth {
  LocalBiometricAuth([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<BiometricKind> available() async {
    // Windows Hello can't be limited to biometrics (it always offers the
    // Windows PIN), and the fallback here is Fusion's own PIN.
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return BiometricKind.none;
    }
    try {
      if (!await _auth.isDeviceSupported() || !await _auth.canCheckBiometrics) {
        return BiometricKind.none;
      }
      final enrolled = await _auth.getAvailableBiometrics();
      if (enrolled.isEmpty) return BiometricKind.none;
      if (enrolled.contains(BiometricType.face)) return BiometricKind.face;
      if (enrolled.contains(BiometricType.fingerprint)) {
        return BiometricKind.fingerprint;
      }
      return BiometricKind.other;
    } catch (_) {
      // No plugin on this platform, or no hardware: PIN only.
      return BiometricKind.none;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    if (kIsWeb) return false;
    try {
      // The fallback is Fusion's own PIN, so never offer the device passcode.
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}
