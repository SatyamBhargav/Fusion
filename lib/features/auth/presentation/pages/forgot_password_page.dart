import 'dart:math' as math;

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
import '../cubits/forgot_password_cubit.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<ForgotPasswordCubit>(),
    child: const _ForgotPasswordView(),
  );
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _shake = GlobalKey<ShakeState>();
  late final AnimationController _wiggle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void initState() {
    super.initState();
    final saved = context.read<ForgotPasswordCubit>().savedEmail;
    if (saved != null) _email.text = saved;
  }

  @override
  void dispose() {
    _email.dispose();
    _wiggle.dispose();
    super.dispose();
  }

  void _send() {
    FocusScope.of(context).unfocus();
    context.read<ForgotPasswordCubit>().send(_email.text);
  }

  void _onEffect(BuildContext context, ForgotPasswordEffect effect) {
    switch (effect) {
      case ForgotPasswordInvalid():
        HapticFeedback.heavyImpact();
        _shake.currentState?.shake();
      case ResetCodeSent(:final code):
        // The banner goes on the app's overlay so it stays up over the
        // next screen.
        final overlay = Navigator.of(context).overlay!;
        context.push(Routes.reset);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => showCodeBanner(overlay, code),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final cubit = context.read<ForgotPasswordCubit>();
    final error = context.watch<ForgotPasswordCubit>().state;
    return EffectListener<ForgotPasswordCubit, ForgotPasswordEffect>(
      listener: _onEffect,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: statusBarFor(context),
        child: Scaffold(
          backgroundColor: fc.bg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Shake(
                key: _shake,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BackButtonF(),
                    const SizedBox(height: 40),
                    PopIn(
                      child: ExcludeSemantics(
                        child: SizedBox(
                          width: 150,
                          height: 140,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 10,
                                child: Transform.rotate(
                                  angle: -0.14,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: fc.lime,
                                      borderRadius: BorderRadius.circular(36),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Blob(size: 56, color: fc.violet),
                              ),
                              Positioned(
                                left: 30,
                                top: 40,
                                child: AnimatedBuilder(
                                  animation: _wiggle,
                                  builder: (_, child) {
                                    // A little "jiggle the key" every cycle.
                                    final t = _wiggle.value;
                                    final w = t < 0.25
                                        ? math.sin(t / 0.25 * math.pi * 4) *
                                              0.18 *
                                              (1 - t / 0.25)
                                        : 0.0;
                                    return Transform.rotate(
                                      angle: -0.14 + w,
                                      child: child,
                                    );
                                  },
                                  child: FIcon(
                                    FIcons.key,
                                    size: 60,
                                    color: fc.onLime,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        'Forgot password?',
                        style: FT.display(36, spacing: -1),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      child: Text(
                        'No worries. Enter the email linked to your vault and we’ll send you a 6-digit reset code.',
                        style: FT.body(16, color: fc.muted, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: FusionField(
                        label: 'Email',
                        controller: _email,
                        icon: FIcons.mail,
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        action: TextInputAction.send,
                        autofillHints: const [AutofillHints.email],
                        error: error,
                        onSubmitted: (_) => _send(),
                        onChanged: (_) => cubit.emailChanged(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 260),
                      child: PrimaryButton(
                        label: 'Send reset code',
                        onTap: _send,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: InlineLink(
                        prefix: 'Remembered it? ',
                        link: 'Back to log in',
                        onTap: () => context.pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
