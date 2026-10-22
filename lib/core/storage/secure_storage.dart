import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Everything Fusion stores lives in the platform's secure storage
/// (AES-GCM with an Android Keystore key / the iOS Keychain).
const fusionStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

/// Storage keys. Existing installs depend on these, so never rename them.
abstract final class StorageKeys {
  static const account = 'fusion.account.v1';
  static const appLock = 'fusion.applock.v1';
  static const theme = 'fusion.theme.v1';
  static const vault = 'fusion.vault.v1';
}
