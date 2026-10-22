import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_theme_mode.dart';
import '../../domain/usecases/load_theme_mode.dart';
import '../../domain/usecases/set_theme_mode.dart';

/// The appearance choice: light, dark, or follow the device.
class ThemeCubit extends Cubit<AppThemeMode> {
  ThemeCubit({
    required LoadThemeMode loadThemeMode,
    required SetThemeMode setThemeMode,
  }) : _load = loadThemeMode,
       _save = setThemeMode,
       super(AppThemeMode.system);

  final LoadThemeMode _load;
  final SetThemeMode _save;

  Future<void> load() async => emit(await _load());

  Future<void> select(AppThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    await _save(mode);
  }
}
