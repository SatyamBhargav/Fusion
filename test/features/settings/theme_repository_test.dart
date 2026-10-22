import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/core/storage/secure_storage.dart';
import 'package:fusion/features/settings/data/datasources/theme_local_data_source.dart';
import 'package:fusion/features/settings/data/repositories/theme_repository_impl.dart';
import 'package:fusion/features/settings/domain/entities/app_theme_mode.dart';

const _repo = ThemeRepositoryImpl(SecureThemeLocalDataSource(fusionStorage));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to system when nothing is stored', () async {
    FlutterSecureStorage.setMockInitialValues({});
    expect(await _repo.load(), AppThemeMode.system);
  });

  test('persists the chosen mode under the old key and name', () async {
    FlutterSecureStorage.setMockInitialValues({});
    await _repo.save(AppThemeMode.dark);
    expect(await _repo.load(), AppThemeMode.dark);
    expect(await fusionStorage.read(key: StorageKeys.theme), 'dark');
  });

  test('falls back to system on an unknown stored value', () async {
    FlutterSecureStorage.setMockInitialValues({StorageKeys.theme: 'sepia'});
    expect(await _repo.load(), AppThemeMode.system);
  });
}
