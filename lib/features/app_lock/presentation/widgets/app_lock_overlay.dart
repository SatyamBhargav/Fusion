import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/app_lock_bloc.dart';
import '../pages/lock_page.dart';

/// Locks the vault whenever the app leaves the screen. The lock covers
/// whatever was open instead of replacing it, so unlocking returns right
/// there with nothing lost — and screens underneath can finish and close
/// themselves without disturbing it.
class AppLockOverlay extends StatefulWidget {
  const AppLockOverlay({super.key, required this.child});

  /// The app's router.
  final Widget child;

  /// Whether the lock is up.
  static bool shown(AppLockState lock, AuthSession auth) =>
      lock.resumeLocked && auth.loggedIn;

  @override
  State<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends State<AppLockOverlay> {
  late final AppLifecycleListener _listener;

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

  void _onHide() {
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<AppLockBloc>().add(const AppHidden());
  }

  @override
  Widget build(BuildContext context) {
    final locked = AppLockOverlay.shown(
      context.watch<AppLockBloc>().state,
      context.watch<AuthBloc>().state,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        // Always the same wrappers, only switched on and off: inserting
        // one would rebuild the router and lose the open screens.
        ExcludeFocus(
          excluding: locked,
          child: ExcludeSemantics(
            excluding: locked,
            child: IgnorePointer(
              ignoring: locked,
              child: TickerMode(enabled: !locked, child: widget.child),
            ),
          ),
        ),
        // Instant on, so the first frame back is already locked.
        AnimatedSwitcher(
          duration: Duration.zero,
          reverseDuration: const Duration(milliseconds: 220),
          child: locked
              ? const _LockLayer(key: ValueKey('lock'))
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// The lock page with what a page expects above it (a navigator, an
/// overlay, its own messenger so toasts from underneath stay there).
class _LockLayer extends StatelessWidget {
  const _LockLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: HeroControllerScope.none(
        child: Navigator(
          pages: const [MaterialPage<void>(child: LockPage(resume: true))],
          onDidRemovePage: (_) {},
        ),
      ),
    );
  }
}
