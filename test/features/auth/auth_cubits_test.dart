import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/app/di/injection.dart';
import 'package:fusion/core/error/result.dart';
import 'package:fusion/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:fusion/features/auth/domain/repositories/auth_repository.dart';
import 'package:fusion/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fusion/features/auth/presentation/cubits/forgot_password_cubit.dart';
import 'package:fusion/features/auth/presentation/cubits/login_cubit.dart';
import 'package:fusion/features/auth/presentation/cubits/reset_password_cubit.dart';
import 'package:fusion/features/auth/presentation/cubits/sign_up_cubit.dart';

import '../../helpers/di.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthBloc', () {
    test('starts from the current session and follows it', () async {
      await setUpDi();
      final bloc = sl<AuthBloc>();
      expect(bloc.state.ready, isTrue);
      expect(bloc.state.loggedIn, isFalse);
      sl<AuthRepository>().unlock();
      await flush();
      expect(bloc.state.loggedIn, isTrue);
    });
  });

  group('LoginCubit', () {
    setUp(() => setUpDi(pin: false));

    test('prefills the account email', () {
      expect(sl<LoginCubit>().savedEmail, 'ada@x.io');
    });

    test('empty fields show errors and fail every time', () async {
      final cubit = sl<LoginCubit>();
      final effects = <LoginEffect>[];
      cubit.effects.listen(effects.add);
      await cubit.submit('nope', '');
      await cubit.submit('nope', '');
      await flush();
      expect(cubit.state.emailError, 'Enter the email you signed up with');
      expect(cubit.state.passwordError, 'Enter your master password');
      expect(effects, [LoginEffect.failed, LoginEffect.failed]);
    });

    test('a wrong password goes under the password field', () async {
      final cubit = sl<LoginCubit>();
      await cubit.submit('ada@x.io', 'wrong');
      expect(cubit.state.passwordError, 'Wrong master password. Try again.');
      expect(cubit.state.loading, isFalse);
    });

    test('a wrong email goes under the email field', () async {
      final cubit = sl<LoginCubit>();
      await cubit.submit('bob@x.io', 'pw');
      expect(cubit.state.emailError, 'That email doesn’t match this vault.');
    });

    test('the right password opens the vault and keeps loading', () async {
      final cubit = sl<LoginCubit>();
      await cubit.submit('ada@x.io', 'pw');
      expect(sl<AuthRepository>().current.loggedIn, isTrue);
      expect(cubit.state.loading, isTrue);
    });

    blocTest<LoginCubit, LoginState>(
      'typing clears that field’s error',
      build: () => sl<LoginCubit>(),
      seed: () => const LoginState(emailError: 'e', passwordError: 'p'),
      act: (c) => c
        ..emailChanged()
        ..passwordChanged(),
      expect: () => const [LoginState(passwordError: 'p'), LoginState()],
    );

    test('can go back to the PIN', () async {
      await setUpDi();
      sl<AppLockRepository>().requestMasterPassword();
      sl<LoginCubit>().usePinInstead();
      expect(sl<AppLockRepository>().current.masterPasswordRequested, isFalse);
    });
  });

  group('SignUpCubit', () {
    setUp(() => setUpDi(account: false, pin: false));

    test('checks every field', () async {
      final cubit = sl<SignUpCubit>();
      await cubit.submit(name: ' ', email: 'x', password: 'short', confirm: '');
      expect(cubit.state.nameError, 'Tell us your name');
      expect(cubit.state.emailError, 'Enter a valid email');
      expect(cubit.state.passwordError, 'Use at least 8 characters');
      expect(cubit.state.confirmError, 'Passwords don’t match');
    });

    test('needs the Terms accepted', () async {
      final cubit = sl<SignUpCubit>();
      final effects = <SignUpEffect>[];
      cubit.effects.listen(effects.add);
      await cubit.submit(
        name: 'Ada',
        email: 'ada@x.io',
        password: 'password-1',
        confirm: 'password-1',
      );
      await flush();
      expect(effects, [SignUpEffect.mustAgree]);
      expect(sl<AuthRepository>().current.hasAccount, isFalse);
    });

    test('creates the account', () async {
      final cubit = sl<SignUpCubit>()..agreeChanged(true);
      await cubit.submit(
        name: 'Ada',
        email: 'ada@x.io',
        password: 'password-1',
        confirm: 'password-1',
      );
      expect(sl<AuthRepository>().current.loggedIn, isTrue);
    });

    test('tracks the strength input and whether the passwords match', () {
      final cubit = sl<SignUpCubit>()..passwordChanged('abc', '');
      expect(cubit.state.password, 'abc');
      expect(cubit.state.matches, isFalse);
      cubit.confirmChanged('abc', 'abc');
      expect(cubit.state.matches, isTrue);
    });
  });

  group('ForgotPasswordCubit', () {
    setUp(() => setUpDi(pin: false));

    test('rejects a malformed or unknown email', () {
      final cubit = sl<ForgotPasswordCubit>()..send('nope');
      expect(cubit.state, 'Enter a valid email');
      cubit.send('bob@x.io');
      expect(cubit.state, 'That email doesn’t match this vault.');
    });

    test('sends a code for the account email', () async {
      final cubit = sl<ForgotPasswordCubit>();
      final effects = <ForgotPasswordEffect>[];
      cubit.effects.listen(effects.add);
      cubit.send('ada@x.io');
      await flush();
      expect(
        (effects.single as ResetCodeSent).code,
        matches(RegExp(r'^\d{6}$')),
      );
    });
  });

  group('ResetPasswordCubit', () {
    late String code;

    setUp(() async {
      await setUpDi(pin: false);
      code =
          (sl<AuthRepository>().requestReset('ada@x.io') as Ok<String>).value;
    });

    test('knows the email and counts down from a minute', () async {
      final cubit = sl<ResetPasswordCubit>();
      expect(cubit.state.email, 'ada@x.io');
      expect(cubit.state.secondsLeft, 60);
      await cubit.close();
    });

    test('checks the code and the new password', () async {
      final cubit = sl<ResetPasswordCubit>();
      await cubit.submit(code: '12', password: 'short', confirm: 'x');
      expect(cubit.state.codeError, 'Enter all 6 digits');
      expect(cubit.state.passwordError, 'Use at least 8 characters');
      expect(cubit.state.confirmError, 'Passwords don’t match');
      await cubit.close();
    });

    test('sets the new password', () async {
      final cubit = sl<ResetPasswordCubit>();
      final effects = <ResetPasswordEffect>[];
      cubit.effects.listen(effects.add);
      await cubit.submit(
        code: code,
        password: 'new-pass-1',
        confirm: 'new-pass-1',
      );
      await flush();
      expect(effects.single, isA<PasswordResetDone>());
      expect(
        (await sl<AuthRepository>().logIn('ada@x.io', 'new-pass-1')).isOk,
        isTrue,
      );
      await cubit.close();
    });

    test('resending gives a new code', () async {
      final cubit = sl<ResetPasswordCubit>();
      final effects = <ResetPasswordEffect>[];
      cubit.effects.listen(effects.add);
      cubit.resend();
      await flush();
      expect(effects.single, isA<ResetCodeResent>());
      await cubit.close();
    });
  });
}
