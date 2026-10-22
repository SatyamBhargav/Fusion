import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../screens/lock_screen.dart';
import '../services/app_lock_controller.dart';
import '../services/auth_service.dart';

/// Locks the vault whenever the app leaves the screen: the lock screen is
/// pushed on top of whatever was open, so unlocking returns right there.
class AppLockGuard extends StatefulWidget {
  const AppLockGuard({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AppLockGuard> createState() => _AppLockGuardState();
}

class _AppLockGuardState extends State<AppLockGuard> {
  late final AppLifecycleListener _listener;
  Route<bool>? _lock;

  @override
  void initState() {
    super.initState();
    // Hide, not inactive: the notification shade, Control Center and the
    // biometric sheet only make the app inactive, so they never lock it.
    _listener = AppLifecycleListener(onHide: _onHide);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  bool get _shouldLock {
    final auth = context.read<AuthService>();
    final lock = context.read<AppLockController>();
    return auth.loggedIn && lock.hasPin;
  }

  void _onHide() {
    if (_lock != null || !_shouldLock) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _push();
  }

  void _push() {
    final nav = widget.navigatorKey.currentState;
    if (nav == null) return;
    final route = lockRoute();
    _lock = route;
    nav.push(route).then((unlocked) {
      if (!identical(_lock, route)) return;
      _lock = null;
      // Something else popped the lock (e.g. a screen closing itself after
      // an await): put it straight back unless the vault was locked anyway.
      if (unlocked != true && mounted && _shouldLock) _push();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
