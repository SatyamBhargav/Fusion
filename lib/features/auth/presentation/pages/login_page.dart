import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/bloc/effects.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/icons.dart';
import '../../../../core/widgets/motion.dart';
import '../../../app_lock/presentation/bloc/app_lock_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../cubits/login_cubit.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<LoginCubit>(), child: const _LoginView());
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _shake = GlobalKey<ShakeState>();

  @override
  void initState() {
    super.initState();
    final saved = context.read<LoginCubit>().savedEmail;
    if (saved != null) _email.text = saved;
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<LoginCubit>().submit(_email.text, _pass.text);
  }

  void _onEffect(BuildContext context, LoginEffect effect) {
    HapticFeedback.heavyImpact();
    _shake.currentState?.shake();
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final cubit = context.read<LoginCubit>();
    final form = context.watch<LoginCubit>().state;
    final auth = context.watch<AuthBloc>().state;
    final lock = context.watch<AppLockBloc>().state.status;
    final canPop = context.canPop();
    final first = auth.firstName;

    return EffectListener<LoginCubit, LoginEffect>(
      listener: _onEffect,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: statusBarFor(context),
        child: Scaffold(
          backgroundColor: fc.bg,
          body: Stack(
            children: [
              Positioned(
                right: -90,
                top: -80,
                child: PopIn(child: Blob(size: 220, color: fc.lime)),
              ),
              Positioned(
                right: 40,
                top: 70,
                child: PopIn(
                  delay: const Duration(milliseconds: 140),
                  child: Blob(size: 120, color: fc.violet.withAlpha(0xE6)),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  child: AutofillGroup(
                    child: Shake(
                      key: _shake,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (canPop) ...[
                                const BackButtonF(),
                                const SizedBox(width: 14),
                              ],
                              const FusionWordmark(),
                            ],
                          ),
                          const SizedBox(height: 56),
                          FadeSlideIn(
                            child: Text(
                              'Welcome back',
                              style: FT.display(38, spacing: -1, height: 1.02),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 60),
                            child: Text(
                              first.isEmpty
                                  ? 'Unlock your vault to continue.'
                                  : 'Unlock your vault to continue, $first.',
                              style: FT.body(16, color: fc.muted),
                            ),
                          ),
                          const SizedBox(height: 28),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 120),
                            child: FusionField(
                              label: 'Email',
                              controller: _email,
                              icon: FIcons.mail,
                              hint: 'you@example.com',
                              keyboardType: TextInputType.emailAddress,
                              action: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              error: form.emailError,
                              onChanged: (_) => cubit.emailChanged(),
                            ),
                          ),
                          const SizedBox(height: 18),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 180),
                            child: FusionField(
                              label: 'Master password',
                              controller: _pass,
                              icon: FIcons.lock,
                              obscure: form.obscure,
                              action: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              error: form.passwordError,
                              onSubmitted: (_) => _submit(),
                              onChanged: (_) => cubit.passwordChanged(),
                              trailing: [
                                EyeButton(
                                  obscured: form.obscure,
                                  onTap: cubit.toggleObscure,
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextLink(
                              'Forgot password?',
                              onTap: () => context.push(Routes.forgot),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 240),
                            child: PrimaryButton(
                              label: 'Log in',
                              trailingIcon: FIcons.arrowRight,
                              loading: form.loading,
                              onTap: _submit,
                            ),
                          ),
                          if (lock.masterPasswordRequested &&
                              lock.hasPin &&
                              !lock.pinLockedOut) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: TextLink(
                                'Unlock with PIN instead',
                                onTap: cubit.usePinInstead,
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          if (!auth.hasAccount)
                            Center(
                              child: InlineLink(
                                prefix: 'New to Fusion? ',
                                link: 'Create an account',
                                onTap: () =>
                                    context.pushReplacement(Routes.signUp),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
