import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/theme/theme.dart';
import 'features/app_lock/domain/usecases/init_app_lock.dart';
import 'features/auth/domain/usecases/init_auth.dart';
import 'features/settings/presentation/cubit/theme_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(darkStatusBar);
  configureDependencies();
  // The splash shows until the account is read.
  sl<InitAuth>()();
  // Read the theme and the app lock before the first frame so there's no
  // flash of the wrong theme or of the master password screen.
  await Future.wait([sl<ThemeCubit>().load(), sl<InitAppLock>()()]);
  runApp(const FusionApp());
}
