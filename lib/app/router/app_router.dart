import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/transitions.dart';
import '../../features/app_lock/presentation/pages/app_lock_setup_page.dart';
import '../../features/app_lock/presentation/pages/lock_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/generator/presentation/pages/generator_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/vault/presentation/pages/login_form_page.dart';
import '../../features/vault/presentation/pages/password_detail_page.dart';
import 'route_guard.dart';
import 'routes.dart';

/// The app's routes. [guard] picks the screen from the account and lock
/// state; everything else is pushed on top of it.
GoRouter buildRouter(RouteGuard guard) {
  // Screens the app switches to by itself fade in; screens opened on top
  // slide in. The login is either, depending on how it was reached.
  Page<void> page(GoRouterState state, Widget child) =>
      guard.isRoot(state.uri.path)
      ? rootPage(state, child)
      : fusionPage(state, child);

  GoRoute route(String path, Widget Function(GoRouterState) build) =>
      GoRoute(path: path, pageBuilder: (_, s) => page(s, build(s)));

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: guard,
    redirect: (_, state) => guard.redirect(state.uri.path),
    routes: [
      route(Routes.splash, (_) => const SplashPage()),
      route(Routes.welcome, (_) => const WelcomePage()),
      route(Routes.login, (_) => const LoginPage()),
      route(Routes.lock, (_) => const LockPage()),
      route(Routes.setup, (_) => const AppLockSetupPage()),
      route(Routes.home, (_) => const HomePage()),
      route(Routes.signUp, (_) => const SignUpPage()),
      route(Routes.forgot, (_) => const ForgotPasswordPage()),
      route(Routes.reset, (_) => const ResetPasswordPage()),
      // Before '/item/:id', which would match it too.
      route(Routes.newItem, (_) => const LoginFormPage()),
      route(
        '/item/:id',
        (s) => PasswordDetailPage(itemId: s.pathParameters['id']!),
      ),
      route(
        '/item/:id/edit',
        (s) => LoginFormPage(itemId: s.pathParameters['id']),
      ),
      route(Routes.pickPassword, (_) => const GeneratorPage(pickMode: true)),
      route(Routes.changePin, (_) => const AppLockSetupPage(change: true)),
    ],
  );
}
