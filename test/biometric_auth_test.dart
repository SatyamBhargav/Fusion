import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/services/biometric_auth.dart';
import 'package:local_auth/local_auth.dart';

class _FakeLocalAuth implements LocalAuthentication {
  bool supported = true;
  bool canCheck = true;
  List<BiometricType> enrolled = const [];
  Object? throwOnEnrolled;
  Object? throwOnAuth;
  bool authResult = true;
  bool? lastBiometricOnly;
  String? lastReason;

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<bool> get canCheckBiometrics async => canCheck;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (throwOnEnrolled != null) throw throwOnEnrolled!;
    return enrolled;
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<Object> authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    lastReason = localizedReason;
    lastBiometricOnly = biometricOnly;
    if (throwOnAuth != null) throw throwOnAuth!;
    return authResult;
  }

  @override
  Future<bool> stopAuthentication() async => true;
}

void main() {
  late _FakeLocalAuth fake;
  late LocalBiometricAuth auth;

  setUp(() {
    fake = _FakeLocalAuth();
    auth = LocalBiometricAuth(fake);
  });

  group('available', () {
    test('is none when the device has no biometric support', () async {
      fake
        ..supported = false
        ..enrolled = const [BiometricType.face];
      expect(await auth.available(), BiometricKind.none);
    });

    test('is none when nothing is enrolled', () async {
      expect(await auth.available(), BiometricKind.none);
    });

    test('prefers face when face is enrolled', () async {
      fake.enrolled = const [BiometricType.fingerprint, BiometricType.face];
      expect(await auth.available(), BiometricKind.face);
    });

    test('reports fingerprint', () async {
      fake.enrolled = const [BiometricType.fingerprint];
      expect(await auth.available(), BiometricKind.fingerprint);
    });

    test('reports a generic kind for strong/weak only', () async {
      fake.enrolled = const [BiometricType.strong];
      expect(await auth.available(), BiometricKind.other);
    });

    test(
      'is none on Windows, where Hello always allows the device PIN',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          fake.enrolled = const [BiometricType.weak, BiometricType.strong];
          expect(await auth.available(), BiometricKind.none);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    test('is none when the plugin throws', () async {
      fake.throwOnEnrolled = const LocalAuthException(
        code: LocalAuthExceptionCode.noBiometricHardware,
      );
      expect(await auth.available(), BiometricKind.none);
    });
  });

  group('authenticate', () {
    test('asks for biometrics only, never the device passcode', () async {
      expect(await auth.authenticate('Unlock Fusion'), isTrue);
      expect(fake.lastBiometricOnly, isTrue);
      expect(fake.lastReason, 'Unlock Fusion');
    });

    test('returns false when the user fails', () async {
      fake.authResult = false;
      expect(await auth.authenticate('Unlock Fusion'), isFalse);
    });

    test('returns false instead of throwing on plugin errors', () async {
      fake.throwOnAuth = const LocalAuthException(
        code: LocalAuthExceptionCode.userCanceled,
      );
      expect(await auth.authenticate('Unlock Fusion'), isFalse);
    });
  });
}
