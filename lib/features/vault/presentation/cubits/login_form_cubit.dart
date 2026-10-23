import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/effects.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/vault_item.dart';
import '../../domain/usecases/save_vault_item.dart';

class LoginFormState extends Equatable {
  const LoginFormState({
    required this.kind,
    required this.provider,
    required this.favourite,
    required this.password,
    this.obscure = true,
    this.saving = false,
    this.nameError,
    this.passwordError,
  });

  final LoginKind kind;

  /// Social provider id.
  final String provider;
  final bool favourite;

  /// The password as typed, for the strength meter.
  final String password;
  final bool obscure;
  final bool saving;
  final String? nameError;
  final String? passwordError;

  LoginFormState copyWith({
    LoginKind? kind,
    String? provider,
    bool? favourite,
    String? password,
    bool? obscure,
    bool? saving,
    String? Function()? nameError,
    String? Function()? passwordError,
  }) => LoginFormState(
    kind: kind ?? this.kind,
    provider: provider ?? this.provider,
    favourite: favourite ?? this.favourite,
    password: password ?? this.password,
    obscure: obscure ?? this.obscure,
    saving: saving ?? this.saving,
    nameError: nameError != null ? nameError() : this.nameError,
    passwordError: passwordError != null ? passwordError() : this.passwordError,
  );

  @override
  List<Object?> get props => [
    kind,
    provider,
    favourite,
    password,
    obscure,
    saving,
    nameError,
    passwordError,
  ];
}

sealed class LoginFormEffect {
  const LoginFormEffect();
}

/// A required field is empty: shake with a buzz.
final class LoginFormInvalid extends LoginFormEffect {
  const LoginFormInvalid();
}

final class LoginFormSaveFailed extends LoginFormEffect {
  const LoginFormSaveFailed(this.message);

  final String message;
}

/// Saved; the form should close.
final class LoginFormSaved extends LoginFormEffect {
  const LoginFormSaved(this.name);

  final String name;
}

/// The text fields a save reads.
class LoginFormFields {
  const LoginFormFields({
    required this.name,
    required this.website,
    required this.username,
    required this.password,
    required this.account,
    required this.note,
  });

  final String name;
  final String website;
  final String username;
  final String password;

  /// The social sign-in account.
  final String account;
  final String note;
}

/// Add or edit a login — either a stored password or a social sign-in.
class LoginFormCubit extends Cubit<LoginFormState>
    with Effects<LoginFormState, LoginFormEffect> {
  LoginFormCubit({
    required this.existing,
    required String? initialPassword,
    required SaveVaultItem saveVaultItem,
  }) : _save = saveVaultItem,
       super(
         LoginFormState(
           kind: existing?.kind ?? LoginKind.password,
           provider: existing?.provider ?? 'google',
           favourite: existing?.favourite ?? false,
           password: existing?.password ?? initialPassword ?? '',
           // A freshly generated password is shown, not hidden.
           obscure: initialPassword == null,
         ),
       );

  /// The item being edited; null for a new login.
  final VaultItem? existing;
  final SaveVaultItem _save;

  bool get isEdit => existing != null;

  void kindChanged(LoginKind kind) =>
      emit(state.copyWith(kind: kind, passwordError: () => null));

  void providerChanged(String id) => emit(state.copyWith(provider: id));

  void favouriteChanged(bool on) => emit(state.copyWith(favourite: on));

  void toggleObscure() => emit(state.copyWith(obscure: !state.obscure));

  void nameChanged() {
    if (state.nameError != null) emit(state.copyWith(nameError: () => null));
  }

  void passwordChanged(String password) =>
      emit(state.copyWith(password: password, passwordError: () => null));

  /// A password picked in the generator, shown so it can be checked.
  void passwordPicked(String password) => emit(
    state.copyWith(
      password: password,
      obscure: false,
      passwordError: () => null,
    ),
  );

  Future<void> save(LoginFormFields f) async {
    if (state.saving) return;
    final isPassword = state.kind == LoginKind.password;
    final nameError = f.name.trim().isEmpty ? 'Give this login a name' : null;
    final passwordError = isPassword && f.password.isEmpty
        ? 'Enter or generate a password'
        : null;
    emit(
      state.copyWith(
        nameError: () => nameError,
        passwordError: () => passwordError,
      ),
    );
    if (nameError != null || passwordError != null) {
      effect(const LoginFormInvalid());
      return;
    }

    final item = VaultItem(
      id: existing?.id ?? newId(),
      name: f.name.trim(),
      website: f.website.trim(),
      username: isPassword ? f.username.trim() : f.account.trim(),
      password: isPassword ? f.password : '',
      note: f.note.trim(),
      favourite: state.favourite,
      kind: state.kind,
      provider: state.provider,
      updatedAt: DateTime.now(),
    );
    emit(state.copyWith(saving: true));
    final result = await _save(SaveVaultItemParams(item, isNew: !isEdit));
    if (isClosed) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(state.copyWith(saving: false));
      effect(LoginFormSaveFailed(failure.message));
      return;
    }
    effect(LoginFormSaved(item.name));
  }
}
