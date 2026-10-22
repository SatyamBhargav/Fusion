import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Everything Fusion stores lives in the platform's secure storage
/// (AES-GCM with an Android Keystore key / the iOS Keychain).
const fusionStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);
