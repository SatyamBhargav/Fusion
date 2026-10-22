import 'package:flutter/foundation.dart';

import '../domain/entities/biometric_kind.dart';

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
