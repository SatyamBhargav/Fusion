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
import '../cubits/sign_up_cubit.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<SignUpCubit>(),
    child: const _SignUpView(),
  );
}

class _SignUpView extends StatefulWidget {
  const _SignUpView();

  @override
  State<_SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<_SignUpView> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _shake = GlobalKey<ShakeState>();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<SignUpCubit>().submit(
      name: _name.text,
      email: _email.text,
      password: _pass.text,
      confirm: _confirm.text,
    );
  }

  void _onEffect(BuildContext context, SignUpEffect effect) {
    if (effect != SignUpEffect.failed) HapticFeedback.heavyImpact();
    _shake.currentState?.shake();
    if (effect == SignUpEffect.mustAgree) {
      showFusionToast(
        context,
        'Please accept the Terms to continue',
        icon: FIcons.info,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final cubit = context.read<SignUpCubit>();
    final form = context.watch<SignUpCubit>().state;
    return EffectListener<SignUpCubit, SignUpEffect>(
      listener: _onEffect,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: statusBarFor(context),
        child: Scaffold(
          backgroundColor: fc.bg,
          body: Stack(
            children: [
              Positioned(
                right: -60,
                top: -50,
                child: PopIn(child: Blob(size: 160, color: fc.lime)),
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
                          const BackButtonF(),
                          const SizedBox(height: 22),
                          FadeSlideIn(
                            child: Text(
                              'Create your vault',
                              style: FT.display(34, spacing: -1),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 60),
                            child: Text(
                              'One master password guards everything else.',
                              style: FT.body(15, color: fc.muted),
                            ),
                          ),
                          const SizedBox(height: 22),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 100),
                            child: FusionField(
                              label: 'Full name',
                              controller: _name,
                              icon: FIcons.user,
                              hint: 'Your name',
                              capitalization: TextCapitalization.words,
                              action: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              error: form.nameError,
                              onChanged: (_) => cubit.nameChanged(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 140),
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
                          const SizedBox(height: 14),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 180),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FusionField(
                                  label: 'Master password',
                                  controller: _pass,
                                  icon: FIcons.lock,
                                  obscure: form.obscure,
                                  action: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  error: form.passwordError,
                                  onChanged: (_) => cubit.passwordChanged(
                                    _pass.text,
                                    _confirm.text,
                                  ),
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
                          const SizedBox(height: 14),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 220),
                            child: FusionField(
                              label: 'Confirm password',
                              controller: _confirm,
                              icon: FIcons.lock,
                              obscure: form.obscure,
                              action: TextInputAction.done,
                              error: form.confirmError,
                              onSubmitted: (_) => _submit(),
                              onChanged: (_) => cubit.confirmChanged(
                                _pass.text,
                                _confirm.text,
                              ),
                              trailing: [
                                AnimatedScale(
                                  scale: form.matches ? 1 : 0,
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutBack,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: FIcon(
                                      FIcons.check,
                                      color: fc.success,
                                      stroke: 2.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _AgreeRow(
                            value: form.agreed,
                            onChanged: cubit.agreeChanged,
                          ),
                          const SizedBox(height: 14),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 260),
                            child: PrimaryButton(
                              label: 'Create account',
                              loading: form.loading,
                              onTap: _submit,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: InlineLink(
                              prefix: 'Already have an account? ',
                              link: 'Log in',
                              onTap: () =>
                                  context.pushReplacement(Routes.login),
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

class _AgreeRow extends StatelessWidget {
  const _AgreeRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Semantics(
      checked: value,
      label: 'I agree to the Terms and Privacy Policy',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value ? fc.violet : fc.surface,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: value ? fc.violet : fc.checkOff,
                    width: 1.5,
                  ),
                ),
                child: AnimatedScale(
                  scale: value ? 1 : 0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  child: const FIcon(
                    FIcons.check,
                    size: 14,
                    color: Colors.white,
                    stroke: 3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: FT.body(14, color: fc.ink2),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms',
                        style: FT.body(
                          14,
                          weight: FontWeight.w700,
                          color: fc.violet,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: FT.body(
                          14,
                          weight: FontWeight.w700,
                          color: fc.violet,
                        ),
                      ),
                    ],
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
