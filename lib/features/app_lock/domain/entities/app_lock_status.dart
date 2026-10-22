import 'package:equatable/equatable.dart';

import 'biometric_kind.dart';

/// The app lock: a 6-digit Fusion PIN plus optional biometric unlock on top
/// of it. After a master password login it is what opens the vault on every
/// launch and return.
class AppLockStatus extends Equatable {
  const AppLockStatus({
    this.ready = false,
    this.hasPin = false,
    this.biometricEnabled = false,
    this.kind = BiometricKind.none,
    this.failed = 0,
    this.masterPasswordRequested = false,
  });

  static const pinLength = 6;
  static const maxAttempts = 5;

  static bool isValidPin(String pin) =>
      pin.length == pinLength && RegExp(r'^\d+$').hasMatch(pin);

  /// False until stored data has been read.
  final bool ready;
  final bool hasPin;
  final bool biometricEnabled;

  /// What the device offers right now.
  final BiometricKind kind;

  /// Wrong PINs in a row, saved across launches.
  final int failed;

  /// The user chose the master password over the PIN on the lock screen.
  final bool masterPasswordRequested;

  bool get canUseBiometric => biometricEnabled && kind != BiometricKind.none;
  int get attemptsLeft => (maxAttempts - failed).clamp(0, maxAttempts);
  bool get pinLockedOut => failed >= maxAttempts;

  AppLockStatus copyWith({
    bool? ready,
    bool? hasPin,
    bool? biometricEnabled,
    BiometricKind? kind,
    int? failed,
    bool? masterPasswordRequested,
  }) {
    return AppLockStatus(
      ready: ready ?? this.ready,
      hasPin: hasPin ?? this.hasPin,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      kind: kind ?? this.kind,
      failed: failed ?? this.failed,
      masterPasswordRequested:
          masterPasswordRequested ?? this.masterPasswordRequested,
    );
  }

  @override
  List<Object?> get props => [
    ready,
    hasPin,
    biometricEnabled,
    kind,
    failed,
    masterPasswordRequested,
  ];
}
