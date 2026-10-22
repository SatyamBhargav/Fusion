import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/effects.dart';
import '../../../../core/error/result.dart';
import '../../domain/usecases/get_pending_reset_email.dart';
import '../../domain/usecases/request_password_reset.dart';
import '../../domain/usecases/reset_password.dart';

class ResetPasswordState extends Equatable {
  const ResetPasswordState({
    required this.email,
    this.codeError,
    this.passwordError,
    this.confirmError,
    this.password = '',
    this.secondsLeft = ResetPasswordCubit.resendAfter,
    this.obscure = true,
    this.loading = false,
  });

  final String email;
  final String? codeError;
  final String? passwordError;
  final String? confirmError;

  /// The new password as typed, for the strength meter.
  final String password;

  /// Until "Resend code" is offered.
  final int secondsLeft;
  final bool obscure;
  final bool loading;

  ResetPasswordState copyWith({
    String? Function()? codeError,
    String? Function()? passwordError,
    String? Function()? confirmError,
    String? password,
    int? secondsLeft,
    bool? obscure,
    bool? loading,
  }) => ResetPasswordState(
    email: email,
    codeError: codeError != null ? codeError() : this.codeError,
    passwordError: passwordError != null ? passwordError() : this.passwordError,
    confirmError: confirmError != null ? confirmError() : this.confirmError,
    password: password ?? this.password,
    secondsLeft: secondsLeft ?? this.secondsLeft,
    obscure: obscure ?? this.obscure,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [
    email,
    codeError,
    passwordError,
    confirmError,
    password,
    secondsLeft,
    obscure,
    loading,
  ];
}

sealed class ResetPasswordEffect {
  const ResetPasswordEffect();
}

/// Shake with a buzz.
final class ResetPasswordFailed extends ResetPasswordEffect {
  const ResetPasswordFailed();
}

/// A new code to show; the code field should be cleared.
final class ResetCodeResent extends ResetPasswordEffect {
  const ResetCodeResent(this.code);

  final String code;
}

final class PasswordResetDone extends ResetPasswordEffect {
  const PasswordResetDone();
}

class ResetPasswordCubit extends Cubit<ResetPasswordState>
    with Effects<ResetPasswordState, ResetPasswordEffect> {
  ResetPasswordCubit({
    required GetPendingResetEmail getPendingEmail,
    required RequestPasswordReset requestReset,
    required ResetPassword resetPassword,
  }) : _requestReset = requestReset,
       _resetPassword = resetPassword,
       super(ResetPasswordState(email: getPendingEmail() ?? '')) {
    _startTimer();
  }

  static const resendAfter = 60;

  final RequestPasswordReset _requestReset;
  final ResetPassword _resetPassword;
  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    emit(state.copyWith(secondsLeft: resendAfter));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.secondsLeft > 0) {
        emit(state.copyWith(secondsLeft: state.secondsLeft - 1));
      } else {
        t.cancel();
      }
    });
  }

  void codeCompleted() {
    if (state.codeError != null) emit(state.copyWith(codeError: () => null));
  }

  void passwordChanged(String password) =>
      emit(state.copyWith(passwordError: () => null, password: password));

  void confirmChanged() => emit(state.copyWith(confirmError: () => null));

  void toggleObscure() => emit(state.copyWith(obscure: !state.obscure));

  void resend() {
    if (_requestReset(state.email) case Ok(value: final code)) {
      emit(state.copyWith(codeError: () => null));
      _startTimer();
      effect(ResetCodeResent(code));
    }
  }

  Future<void> submit({
    required String code,
    required String password,
    required String confirm,
  }) async {
    if (state.loading) return;
    final codeError = code.length != 6 ? 'Enter all 6 digits' : null;
    final passwordError = password.length < 8
        ? 'Use at least 8 characters'
        : null;
    final confirmError = confirm != password || confirm.isEmpty
        ? 'Passwords don’t match'
        : null;
    emit(
      state.copyWith(
        codeError: () => codeError,
        passwordError: () => passwordError,
        confirmError: () => confirmError,
      ),
    );
    if (codeError != null || passwordError != null || confirmError != null) {
      effect(const ResetPasswordFailed());
      return;
    }

    emit(state.copyWith(loading: true));
    final result = await _resetPassword(
      ResetPasswordParams(code: code, newPassword: password),
    );
    if (isClosed) return;
    final failure = result.failureOrNull;
    if (failure == null) {
      effect(const PasswordResetDone());
      return;
    }
    emit(state.copyWith(loading: false, codeError: () => failure.message));
    effect(const ResetPasswordFailed());
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
