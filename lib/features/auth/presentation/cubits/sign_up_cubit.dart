import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/effects.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/usecases/sign_up.dart';

class SignUpState extends Equatable {
  const SignUpState({
    this.nameError,
    this.emailError,
    this.passwordError,
    this.confirmError,
    this.password = '',
    this.matches = false,
    this.agreed = false,
    this.obscure = true,
    this.loading = false,
  });

  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String? confirmError;

  /// The password as typed, for the strength meter.
  final String password;

  /// The confirmation is filled in and equals the password.
  final bool matches;
  final bool agreed;
  final bool obscure;
  final bool loading;

  SignUpState copyWith({
    String? Function()? nameError,
    String? Function()? emailError,
    String? Function()? passwordError,
    String? Function()? confirmError,
    String? password,
    bool? matches,
    bool? agreed,
    bool? obscure,
    bool? loading,
  }) => SignUpState(
    nameError: nameError != null ? nameError() : this.nameError,
    emailError: emailError != null ? emailError() : this.emailError,
    passwordError: passwordError != null ? passwordError() : this.passwordError,
    confirmError: confirmError != null ? confirmError() : this.confirmError,
    password: password ?? this.password,
    matches: matches ?? this.matches,
    agreed: agreed ?? this.agreed,
    obscure: obscure ?? this.obscure,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [
    nameError,
    emailError,
    passwordError,
    confirmError,
    password,
    matches,
    agreed,
    obscure,
    loading,
  ];
}

enum SignUpEffect {
  /// A field is wrong: shake with a buzz.
  invalid,

  /// The Terms aren't accepted: shake, buzz and say so.
  mustAgree,

  /// Creating the vault failed: shake.
  failed,
}

class SignUpCubit extends Cubit<SignUpState>
    with Effects<SignUpState, SignUpEffect> {
  SignUpCubit({required SignUp signUp})
    : _signUp = signUp,
      super(const SignUpState());

  final SignUp _signUp;

  static bool _matches(String password, String confirm) =>
      confirm.isNotEmpty && confirm == password;

  void nameChanged() => emit(state.copyWith(nameError: () => null));

  void emailChanged() => emit(state.copyWith(emailError: () => null));

  void passwordChanged(String password, String confirm) => emit(
    state.copyWith(
      passwordError: () => null,
      password: password,
      matches: _matches(password, confirm),
    ),
  );

  void confirmChanged(String password, String confirm) => emit(
    state.copyWith(
      confirmError: () => null,
      matches: _matches(password, confirm),
    ),
  );

  void agreeChanged(bool agreed) => emit(state.copyWith(agreed: agreed));

  void toggleObscure() => emit(state.copyWith(obscure: !state.obscure));

  Future<void> submit({
    required String name,
    required String email,
    required String password,
    required String confirm,
  }) async {
    if (state.loading) return;
    final nameError = name.trim().isEmpty ? 'Tell us your name' : null;
    final emailError = looksLikeEmail(email) ? null : 'Enter a valid email';
    final passwordError = password.length < 8
        ? 'Use at least 8 characters'
        : null;
    final confirmError = _matches(password, confirm)
        ? null
        : 'Passwords don’t match';
    emit(
      state.copyWith(
        nameError: () => nameError,
        emailError: () => emailError,
        passwordError: () => passwordError,
        confirmError: () => confirmError,
      ),
    );
    if (nameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmError != null) {
      effect(SignUpEffect.invalid);
      return;
    }
    if (!state.agreed) {
      effect(SignUpEffect.mustAgree);
      return;
    }

    emit(state.copyWith(loading: true));
    final result = await _signUp(
      SignUpParams(name: name, email: email, password: password),
    );
    if (isClosed) return;
    final failure = result.failureOrNull;
    if (failure == null) return; // The router moves on to PIN setup.
    emit(state.copyWith(loading: false, emailError: () => failure.message));
    effect(SignUpEffect.failed);
  }
}
