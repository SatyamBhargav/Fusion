import '../../domain/entities/app_theme_mode.dart';
import '../../domain/repositories/theme_repository.dart';
import '../datasources/theme_local_data_source.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  const ThemeRepositoryImpl(this._local);

  final ThemeLocalDataSource _local;

  @override
  Future<AppThemeMode> load() async {
    try {
      final raw = await _local.read();
      return AppThemeMode.values.firstWhere(
        (m) => m.name == raw,
        orElse: () => AppThemeMode.system,
      );
    } catch (_) {
      // Unreadable storage: follow the device.
      return AppThemeMode.system;
    }
  }

  @override
  Future<void> save(AppThemeMode mode) async {
    try {
      await _local.write(mode.name);
    } catch (_) {
      // Keep the in-memory choice even if it can't be saved.
    }
  }
}
