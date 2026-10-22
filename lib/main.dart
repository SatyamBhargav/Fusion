import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/app_lock_setup_screen.dart';
import 'screens/home_shell.dart';
import 'screens/lock_screen.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/app_lock_controller.dart';
import 'services/auth_service.dart';
import 'services/theme_controller.dart';
import 'services/vault_store.dart';
import 'theme.dart';
import 'widgets/app_lock_guard.dart';
import 'widgets/components.dart';
import 'widgets/motion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(darkStatusBar);
  final auth = AuthService()..init();
  final lock = AppLockController(auth: auth);
  // Read the theme and the app lock before the first frame so there's no
  // flash of the wrong theme or of the master password screen.
  final theme = ThemeController();
  await Future.wait([theme.init(), lock.init()]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<AppLockController>.value(value: lock),
        ChangeNotifierProvider<ThemeController>.value(value: theme),
        ChangeNotifierProvider<VaultStore>(create: (_) => VaultStore()),
      ],
      child: const FusionApp(),
    ),
  );
}

final _navigatorKey = GlobalKey<NavigatorState>();

class FusionApp extends StatelessWidget {
  const FusionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fusion',
      navigatorKey: _navigatorKey,
      builder: (context, child) =>
          AppLockGuard(navigatorKey: _navigatorKey, child: child!),
      debugShowCheckedModeBanner: false,
      theme: buildFusionTheme(FC.light, Brightness.light),
      darkTheme: buildFusionTheme(FC.dark, Brightness.dark),
      themeMode: context.watch<ThemeController>().mode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeOutCubic,
      home: const AuthGate(),
    );
  }
}

/// Picks the root screen from the account and app-lock state and
/// cross-fades between them.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final lock = context.watch<AppLockController>();
    final Widget child;
    if (!auth.ready) {
      child = const _Splash(key: ValueKey('splash'));
    } else if (auth.loggedIn && !lock.hasPin) {
      child = const AppLockSetupScreen(key: ValueKey('setup'));
    } else if (auth.loggedIn) {
      child = const HomeShell(key: ValueKey('home'));
    } else if (auth.hasAccount &&
        lock.hasPin &&
        !lock.masterPasswordRequested) {
      child = const LockScreen(key: ValueKey('lock'));
    } else if (auth.hasAccount) {
      child = const LoginScreen(key: ValueKey('login'));
    } else {
      child = const WelcomeScreen(key: ValueKey('welcome'));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (c, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(
          scale: Tween(begin: 0.97, end: 1.0).animate(a),
          child: c,
        ),
      ),
      child: child,
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightStatusBar,
      child: Scaffold(
        backgroundColor: context.fc.violet,
        body: const Center(
          child: PopIn(child: FusionLogo(size: 80, left: Colors.white)),
        ),
      ),
    );
  }
}
