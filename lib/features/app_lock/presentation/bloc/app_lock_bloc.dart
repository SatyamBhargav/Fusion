import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/domain/usecases/watch_auth_session.dart';
import '../../domain/entities/app_lock_status.dart';
import '../../domain/usecases/get_app_lock_status.dart';
import '../../domain/usecases/should_lock_on_hide.dart';
import '../../domain/usecases/watch_app_lock_status.dart';

sealed class AppLockEvent {
  const AppLockEvent();
}

/// The app left the screen.
final class AppHidden extends AppLockEvent {
  const AppHidden();
}

/// The lock shown on return was unlocked.
final class ResumeUnlocked extends AppLockEvent {
  const ResumeUnlocked();
}

final class _StatusChanged extends AppLockEvent {
  const _StatusChanged(this.status);

  final AppLockStatus status;
}

final class _LoggedOut extends AppLockEvent {
  const _LoggedOut();
}

class AppLockState extends Equatable {
  const AppLockState({required this.status, this.resumeLocked = false});

  final AppLockStatus status;

  /// The lock covers whatever was open since the app was hidden.
  final bool resumeLocked;

  AppLockState copyWith({AppLockStatus? status, bool? resumeLocked}) =>
      AppLockState(
        status: status ?? this.status,
        resumeLocked: resumeLocked ?? this.resumeLocked,
      );

  @override
  List<Object?> get props => [status, resumeLocked];
}

/// The app lock's settings, plus whether the vault is locked over the
/// current screen after the app came back.
class AppLockBloc extends Bloc<AppLockEvent, AppLockState> {
  AppLockBloc({
    required GetAppLockStatus getStatus,
    required WatchAppLockStatus watchStatus,
    required WatchAuthSession watchSession,
    required ShouldLockOnHide shouldLockOnHide,
  }) : super(AppLockState(status: getStatus())) {
    on<_StatusChanged>((e, emit) => emit(state.copyWith(status: e.status)));
    on<_LoggedOut>((e, emit) => emit(state.copyWith(resumeLocked: false)));
    on<ResumeUnlocked>((e, emit) => emit(state.copyWith(resumeLocked: false)));
    on<AppHidden>((e, emit) {
      if (shouldLockOnHide()) emit(state.copyWith(resumeLocked: true));
    });
    _status = watchStatus().listen((s) => add(_StatusChanged(s)));
    _session = watchSession().listen((AuthSession s) {
      if (!s.loggedIn) add(const _LoggedOut());
    });
  }

  late final StreamSubscription<AppLockStatus> _status;
  late final StreamSubscription<AuthSession> _session;

  @override
  Future<void> close() async {
    await _status.cancel();
    await _session.cancel();
    return super.close();
  }
}
