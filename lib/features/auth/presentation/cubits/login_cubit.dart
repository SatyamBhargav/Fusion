import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/effects.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/utils.dart';
import '../../../app_lock/domain/usecases/cancel_master_password.dart';
import '../../domain/usecases/get_auth_session.dart';
import '../../domain/usecases/log_in_with_password.dart';

class LoginState extends Equatable {
  const LoginState({
    this.emailError,
    this.passwordError,
    this.obscure = true,
    this.loading = false,
  });

  final String? emailError;
  final String? passwordError;
  final bool obscure;
  final bool loading;

  LoginState copyWith({
    String? Function()? emailError,
    String? Function()? passwordError,
    bool? obscure,
    bool? loading,
  }) => LoginState(
    emailError: emailError != null ? emailError() : this.emailError,
    passwordError: passwordError != null ? passwordError() : this.passwordError,
    obscure: obscure ?? this.obscure,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [emailError, passwordError, obscure, loading];
}

enum LoginEffect { failed }

/// Master password login. Success needs no navigation: the router moves on
/// once the vault is open.
class LoginCubit extends Cubit<LoginState>
    with Effects<LoginState, LoginEffect> {
  LoginCubit({
    required GetAuthSession getSession,
    required LogInWithPassword logIn,
    required CancelMasterPassword cancelMasterPassword,
  }) : _getSession = getSession,
       _logIn = logIn,
       _cancelMasterPassword = cancelMasterPassword,
       super(const LoginState());

  final GetAuthSession _getSession;
  final LogInWithPassword _logIn;
  final CancelMasterPassword _cancelMasterPassword;

  /// The account's email, to prefill the field.
  String? get savedEmail => _getSession().account?.email;

  void emailChanged() {
    if (state.emailError != null) emit(state.copyWith(emailError: () => null));
  }

  void passwordChanged() {
    if (state.passwordError != null) {
      emit(state.copyWith(passwordError: () => null));
    }
  }

  void toggleObscure() => emit(state.copyWith(obscure: !state.obscure));

  /// Back to the PIN lock.
  void usePinInstead() => _cancelMasterPassword();

  Future<void> submit(String email, String password) async {
    if (state.loading) return;
    final emailError = looksLikeEmail(email)
        ? null
        : 'Enter the email you signed up with';
    final passwordError = password.isEmpty
        ? 'Enter your master password'
        : null;
    emit(
      state.copyWith(
        emailError: () => emailError,
        passwordError: () => passwordError,
      ),
    );
    if (emailError != null || passwordError != null) {
      effect(LoginEffect.failed);
      return;
    }

    emit(state.copyWith(loading: true));
    final result = await _logIn(LogInParams(email: email, password: password));
    if (isClosed) return;
    switch (result.failureOrNull) {
      case null:
        // Stays loading until the router swaps the screen.
        return;
      case AuthFailure(field: AuthField.email, :final message):
        emit(state.copyWith(loading: false, emailError: () => message));
      case final failure:
        emit(
          state.copyWith(loading: false, passwordError: () => failure.message),
        );
    }
    effect(LoginEffect.failed);
  }
}
