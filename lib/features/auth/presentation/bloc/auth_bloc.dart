import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/get_auth_session.dart';
import '../../domain/usecases/watch_auth_session.dart';

sealed class AuthEvent {
  const AuthEvent();
}

final class _AuthSessionChanged extends AuthEvent {
  const _AuthSessionChanged(this.session);

  final AuthSession session;
}

/// The account and whether the vault is open, for widgets to show.
class AuthBloc extends Bloc<AuthEvent, AuthSession> {
  AuthBloc({
    required GetAuthSession getSession,
    required WatchAuthSession watchSession,
  }) : super(getSession()) {
    on<_AuthSessionChanged>((e, emit) => emit(e.session));
    _sub = watchSession().listen((s) => add(_AuthSessionChanged(s)));
  }

  late final StreamSubscription<AuthSession> _sub;

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
