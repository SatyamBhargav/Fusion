import '../entities/app_theme_mode.dart';

abstract interface class ThemeRepository {
  /// The saved choice; [AppThemeMode.system] when none or unreadable.
  Future<AppThemeMode> load();

  /// Saves [mode]; failures are ignored so the in-memory choice still holds.
  Future<void> save(AppThemeMode mode);
}
