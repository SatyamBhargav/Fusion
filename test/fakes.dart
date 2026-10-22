import 'package:fusion/services/biometric_auth.dart';

class FakeBiometricAuth implements BiometricAuth {
  FakeBiometricAuth({this.kind = BiometricKind.face, this.result = true});

  BiometricKind kind;
  bool result;
  int prompts = 0;

  @override
  Future<BiometricKind> available() async => kind;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return result;
  }
}

/// Instant stand-in for the 20k-round hash so tests don't wait on isolates.
Future<String> fastHash(String salt, String secret) async => '$salt|$secret';
