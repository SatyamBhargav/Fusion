import '../../../../core/usecase/usecase.dart';
import '../entities/app_theme_mode.dart';
import '../repositories/theme_repository.dart';

class LoadThemeMode implements UseCase<Future<AppThemeMode>, NoParams> {
  const LoadThemeMode(this._theme);

  final ThemeRepository _theme;

  @override
  Future<AppThemeMode> call([NoParams _ = const NoParams()]) => _theme.load();
}
