import 'package:equatable/equatable.dart';

import 'account.dart';

/// Whether the vault is open, and how it was opened.
class AuthSession extends Equatable {
  const AuthSession({
    this.ready = false,
    this.loggedIn = false,
    bool passwordVerified = false,
    this.account,
  }) : _passwordVerified = passwordVerified;

  /// False until stored data has been read.
  final bool ready;
  final bool loggedIn;
  final bool _passwordVerified;
  final Account? account;

  bool get hasAccount => account != null;

  /// True when this session was opened with the master password (not the
  /// app lock), e.g. so a forgotten PIN can be replaced without the old one.
  bool get passwordVerified => loggedIn && _passwordVerified;

  String get firstName => account?.firstName ?? '';

  AuthSession copyWith({
    bool? ready,
    bool? loggedIn,
    bool? passwordVerified,
    Account? Function()? account,
  }) {
    return AuthSession(
      ready: ready ?? this.ready,
      loggedIn: loggedIn ?? this.loggedIn,
      passwordVerified: passwordVerified ?? _passwordVerified,
      account: account != null ? account() : this.account,
    );
  }

  @override
  List<Object?> get props => [ready, loggedIn, _passwordVerified, account];
}
