import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../features/app_lock/domain/usecases/get_app_lock_status.dart';
import '../../features/app_lock/domain/usecases/watch_app_lock_status.dart';
import '../../features/auth/domain/usecases/get_auth_session.dart';
import '../../features/auth/domain/usecases/watch_auth_session.dart';
import 'routes.dart';

/// The only parts of the account and lock state that decide the screen.
class RoutingState extends Equatable {
  const RoutingState({
    required this.ready,
    required this.loggedIn,
    required this.hasAccount,
    required this.hasPin,
    required this.masterPasswordRequested,
  });

  final bool ready;
  final bool loggedIn;
  final bool hasAccount;
  final bool hasPin;
  final bool masterPasswordRequested;

  @override
  List<Object?> get props => [
    ready,
    loggedIn,
    hasAccount,
    hasPin,
    masterPasswordRequested,
  ];
}

/// Decides where the app may be, and tells the router when that changes.
///
/// It reads the repositories' current values, which every use case updates
/// before returning, so it never sees a half-applied change. It notifies
/// only when [RoutingState] changes: every refresh makes go_router rebuild
/// its stack from the saved location, which would cut pending results
/// (like the picked password) loose.
class RouteGuard extends ChangeNotifier {
  RouteGuard({
    required GetAuthSession getSession,
    required GetAppLockStatus getLockStatus,
    required WatchAuthSession watchSession,
    required WatchAppLockStatus watchLockStatus,
  }) : _getSession = getSession,
       _getLockStatus = getLockStatus {
    _state = _read();
    _subs = [
      watchSession().listen((_) => _update()),
      watchLockStatus().listen((_) => _update()),
    ];
  }

  final GetAuthSession _getSession;
  final GetAppLockStatus _getLockStatus;
  late final List<StreamSubscription<Object?>> _subs;
  late RoutingState _state;

  RoutingState get state => _state;

  RoutingState _read() {
    final s = _getSession();
    final l = _getLockStatus();
    return RoutingState(
      ready: s.ready && l.ready,
      loggedIn: s.loggedIn,
      hasAccount: s.hasAccount,
      hasPin: l.hasPin,
      masterPasswordRequested: l.masterPasswordRequested,
    );
  }

  void _update() {
    final next = _read();
    if (next == _state) return;
    _state = next;
    notifyListeners();
  }

  /// Whether [path] is the screen the app shows by itself right now (as
  /// opposed to one opened on top of it).
  bool isRoot(String path) => _zone(_state).$1 == path;

  /// Where [path] should go instead, or null if it's allowed right now.
  String? redirect(String path) {
    final (root, allowed) = _zone(_state);
    return allowed(path) ? null : root;
  }

  static (String, bool Function(String)) _zone(RoutingState s) {
    if (!s.ready) return (Routes.splash, (p) => p == Routes.splash);
    if (s.loggedIn && !s.hasPin) {
      return (Routes.setup, (p) => p == Routes.setup);
    }
    if (s.loggedIn) {
      return (
        Routes.home,
        (p) =>
            p == Routes.home ||
            p.startsWith('/item/') ||
            p == Routes.pickPassword ||
            p == Routes.changePin,
      );
    }
    if (s.hasAccount && s.hasPin && !s.masterPasswordRequested) {
      return (Routes.lock, (p) => p == Routes.lock);
    }
    if (s.hasAccount) {
      return (
        Routes.login,
        (p) => p == Routes.login || p == Routes.forgot || p == Routes.reset,
      );
    }
    return (
      Routes.welcome,
      (p) =>
          p == Routes.welcome ||
          p == Routes.login ||
          p == Routes.signUp ||
          p == Routes.forgot ||
          p == Routes.reset,
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
