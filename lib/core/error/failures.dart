import 'package:equatable/equatable.dart';

/// Something a use case couldn't do, in words the user can be shown.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Which form field an [AuthFailure] belongs under.
enum AuthField { email, password, code }

final class AuthFailure extends Failure {
  const AuthFailure(this.field, super.message);

  final AuthField field;

  @override
  List<Object?> get props => [field, message];
}

/// Secure storage couldn't be read or written.
final class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Couldn’t save. Please try again.']);
}

/// A request to a server failed. Nothing uses the network yet; this is
/// what the dio layer maps its errors to.
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {this.statusCode});

  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}
