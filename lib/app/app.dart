import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme.dart';
import '../features/app_lock/presentation/bloc/app_lock_bloc.dart';
import '../features/app_lock/presentation/widgets/app_lock_overlay.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/settings/domain/entities/app_theme_mode.dart';
import '../features/settings/presentation/cubit/theme_cubit.dart';
import '../features/settings/presentation/theme_mode_x.dart';
import '../features/vault/presentation/bloc/vault_bloc.dart';
import 'di/injection.dart';
import 'router/lock_back_button_dispatcher.dart';

class FusionApp extends StatefulWidget {
  const FusionApp({super.key});

  @override
  State<FusionApp> createState() => _FusionAppState();
}

class _FusionAppState extends State<FusionApp> {
  final _router = sl<GoRouter>();
  final _back = LockBackButtonDispatcher(
    () => AppLockOverlay.shown(sl<AppLockBloc>().state, sl<AuthBloc>().state),
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<AuthBloc>()),
        BlocProvider.value(value: sl<AppLockBloc>()),
        BlocProvider.value(value: sl<VaultBloc>()),
        BlocProvider.value(value: sl<ThemeCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, AppThemeMode>(
        builder: (context, mode) => MaterialApp.router(
          title: 'Fusion',
          debugShowCheckedModeBanner: false,
          theme: buildFusionTheme(FC.light, Brightness.light),
          darkTheme: buildFusionTheme(FC.dark, Brightness.dark),
          themeMode: mode.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 300),
          themeAnimationCurve: Curves.easeOutCubic,
          routerDelegate: _router.routerDelegate,
          routeInformationParser: _router.routeInformationParser,
          routeInformationProvider: _router.routeInformationProvider,
          backButtonDispatcher: _back,
          // The page colour behind the router, so screens the app switches
          // to fade in from it rather than from black.
          builder: (context, child) => ColoredBox(
            color: context.fc.bg,
            child: AppLockOverlay(child: child!),
          ),
        ),
      ),
    );
  }
}
