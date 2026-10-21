import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/components.dart';
import '../widgets/feedback.dart';
import '../widgets/icons.dart';
import '../widgets/motion.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _shake = GlobalKey<ShakeState>();
  late final AnimationController _wiggle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();
  String? _error;

  @override
  void initState() {
    super.initState();
    final saved = context.read<AuthService>().email;
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
    if (!looksLikeEmail(_email.text)) {
      setState(() => _error = 'Enter a valid email');
      HapticFeedback.heavyImpact();
      _shake.currentState?.shake();
      return;
    }
    final res = context.read<AuthService>().requestReset(_email.text);
    if (res.error != null) {
      setState(() => _error = res.error);
      HapticFeedback.heavyImpact();
      _shake.currentState?.shake();
      return;
    }
    final nav = Navigator.of(context);
    final overlay = nav.overlay!;
    nav.push(fusionRoute(ResetPasswordScreen(email: _email.text.trim())));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => showCodeBanner(overlay, res.code!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: darkStatusBar,
      child: Scaffold(
        backgroundColor: FC.bg,
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
                                    color: FC.lime,
                                    borderRadius: BorderRadius.circular(36),
                                  ),
                                ),
                              ),
                            ),
                            const Positioned(
                              right: 0,
                              top: 0,
                              child: Blob(size: 56, color: FC.violet),
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
                                child: const FIcon(FIcons.key, size: 60),
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
                      style: FT.body(16, color: FC.muted, height: 1.5),
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
                      error: _error,
                      onSubmitted: (_) => _send(),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
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
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
