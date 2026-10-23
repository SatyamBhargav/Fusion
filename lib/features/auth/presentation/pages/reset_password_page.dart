import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/bloc/effects.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/icons.dart';
import '../../../../core/widgets/motion.dart';
import '../cubits/reset_password_cubit.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<ResetPasswordCubit>(),
    child: const _ResetPasswordView(),
  );
}

class _ResetPasswordView extends StatefulWidget {
  const _ResetPasswordView();

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  final _code = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _shake = GlobalKey<ShakeState>();

  @override
  void dispose() {
    _code.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<ResetPasswordCubit>().submit(
      code: _code.text,
      password: _pass.text,
      confirm: _confirm.text,
    );
  }

  void _onEffect(BuildContext context, ResetPasswordEffect effect) {
    switch (effect) {
      case ResetPasswordFailed():
        HapticFeedback.heavyImpact();
        _shake.currentState?.shake();
      case ResetCodeResent(:final code):
        showCodeBanner(Navigator.of(context).overlay!, code);
        _code.clear();
      case PasswordResetDone():
        final messenger = ScaffoldMessenger.of(context);
        context.go(Routes.login);
        showFusionToastOn(
          messenger,
          'Password updated. Log in with your new one.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final cubit = context.read<ResetPasswordCubit>();
    final form = context.watch<ResetPasswordCubit>().state;
    final m = (form.secondsLeft ~/ 60).toString();
    final s = (form.secondsLeft % 60).toString().padLeft(2, '0');

    return EffectListener<ResetPasswordCubit, ResetPasswordEffect>(
      listener: _onEffect,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: statusBarFor(context),
        child: Scaffold(
          backgroundColor: fc.bg,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    child: Shake(
                      key: _shake,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BackButtonF(),
                          const SizedBox(height: 24),
                          FadeSlideIn(
                            child: Text(
                              'Check your inbox',
                              style: FT.display(36, spacing: -1),
                            ),
                          ),
                          const SizedBox(height: 10),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 60),
                            child: Text.rich(
                              TextSpan(
                                style: FT.body(
                                  16,
                                  color: fc.muted,
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'We sent a 6-digit code for ',
                                  ),
                                  TextSpan(
                                    text: form.email,
                                    style: FT.body(
                                      16,
                                      weight: FontWeight.w700,
                                      color: fc.ink,
                                      height: 1.5,
                                    ),
                                  ),
                                  const TextSpan(
                                    text:
                                        '. Enter it below and choose a new password.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 120),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reset code',
                                  style: FT.label(color: fc.ink2),
                                ),
                                const SizedBox(height: 10),
                                OtpInput(
                                  controller: _code,
                                  error: form.codeError != null,
                                  onCompleted: cubit.codeCompleted,
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  alignment: Alignment.topLeft,
                                  child: form.codeError == null
                                      ? const SizedBox(width: double.infinity)
                                      : Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            form.codeError!,
                                            style: FT.body(
                                              13,
                                              weight: FontWeight.w600,
                                              color: fc.danger,
                                            ),
                                          ),
                                        ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Didn’t get it?',
                                      style: FT.body(14, color: fc.muted),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      transitionBuilder: (c, a) =>
                                          FadeTransition(opacity: a, child: c),
                                      child: form.secondsLeft > 0
                                          ? Padding(
                                              key: const ValueKey('wait'),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              child: Text.rich(
                                                TextSpan(
                                                  style: FT.body(
                                                    14,
                                                    color: fc.muted,
                                                  ),
                                                  children: [
                                                    const TextSpan(
                                                      text: 'Resend in ',
                                                    ),
                                                    TextSpan(
                                                      text: '$m:$s',
                                                      style: FT.mono(
                                                        14,
                                                        weight: FontWeight.w500,
                                                        color: fc.ink,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : TextLink(
                                              'Resend code',
                                              key: const ValueKey('resend'),
                                              onTap: cubit.resend,
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 180),
                            child: Column(
                              children: [
                                FusionField(
                                  label: 'New password',
                                  controller: _pass,
                                  icon: FIcons.lock,
                                  hint: 'At least 8 characters',
                                  obscure: form.obscure,
                                  action: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  error: form.passwordError,
                                  onChanged: cubit.passwordChanged,
                                  trailing: [
                                    EyeButton(
                                      obscured: form.obscure,
                                      onTap: cubit.toggleObscure,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                StrengthMeter(password: form.password),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 220),
                            child: FusionField(
                              label: 'Confirm new password',
                              controller: _confirm,
                              icon: FIcons.lock,
                              hint: 'Type it once more',
                              obscure: form.obscure,
                              action: TextInputAction.done,
                              error: form.confirmError,
                              onSubmitted: (_) => _submit(),
                              onChanged: (_) => cubit.confirmChanged(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: PrimaryButton(
                    label: 'Reset password',
                    loading: form.loading,
                    onTap: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
