import '../../../../core/usecase/usecase.dart';
import '../entities/app_theme_mode.dart';
import '../repositories/theme_repository.dart';

class SetThemeMode implements UseCase<Future<void>, AppThemeMode> {
  const SetThemeMode(this._theme);

  final ThemeRepository _theme;

  @override
  Future<void> call(AppThemeMode mode) => _theme.save(mode);
}
