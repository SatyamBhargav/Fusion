import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/effects.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/usecases/get_auth_session.dart';
import '../../domain/usecases/request_password_reset.dart';

sealed class ForgotPasswordEffect {
  const ForgotPasswordEffect();
}

final class ForgotPasswordInvalid extends ForgotPasswordEffect {
  const ForgotPasswordInvalid();
}

/// The code to show, since there's no mail server to send it.
final class ResetCodeSent extends ForgotPasswordEffect {
  const ResetCodeSent(this.code);

  final String code;
}

/// State is the email field's error, if any.
class ForgotPasswordCubit extends Cubit<String?>
    with Effects<String?, ForgotPasswordEffect> {
  ForgotPasswordCubit({
    required GetAuthSession getSession,
    required RequestPasswordReset requestReset,
  }) : _getSession = getSession,
       _requestReset = requestReset,
       super(null);

  final GetAuthSession _getSession;
  final RequestPasswordReset _requestReset;

  String? get savedEmail => _getSession().account?.email;

  void emailChanged() {
    if (state != null) emit(null);
  }

  void send(String email) {
    if (!looksLikeEmail(email)) {
      emit('Enter a valid email');
      effect(const ForgotPasswordInvalid());
      return;
    }
    switch (_requestReset(email)) {
      case Ok(value: final code):
        effect(ResetCodeSent(code));
      case Err(:final failure):
        emit(failure.message);
        effect(const ForgotPasswordInvalid());
    }
  }
}
