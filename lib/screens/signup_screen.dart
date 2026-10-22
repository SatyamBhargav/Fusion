import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../core/theme/theme.dart';
import '../core/utils/utils.dart';
import '../core/widgets/components.dart';
import '../core/widgets/feedback.dart';
import '../core/widgets/icons.dart';
import '../core/widgets/motion.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _shake = GlobalKey<ShakeState>();
  bool _obscure = true;
  bool _agree = false;
  bool _loading = false;
  String? _nameErr, _emailErr, _passErr, _confirmErr;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _matches => _confirm.text.isNotEmpty && _confirm.text == _pass.text;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _nameErr = _name.text.trim().isEmpty ? 'Tell us your name' : null;
      _emailErr = looksLikeEmail(_email.text) ? null : 'Enter a valid email';
      _passErr = _pass.text.length < 8 ? 'Use at least 8 characters' : null;
      _confirmErr = _matches ? null : 'Passwords don’t match';
    });
    if (_nameErr != null ||
        _emailErr != null ||
        _passErr != null ||
        _confirmErr != null) {
      HapticFeedback.heavyImpact();
      _shake.currentState?.shake();
      return;
    }
    if (!_agree) {
      HapticFeedback.heavyImpact();
      _shake.currentState?.shake();
      showFusionToast(
        context,
        'Please accept the Terms to continue',
        icon: FIcons.info,
      );
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final nav = Navigator.of(context);
    AuthError? err;
    try {
      err = await auth.signUp(
        name: _name.text,
        email: _email.text,
        password: _pass.text,
      );
    } catch (_) {
      err = (field: 'email', message: 'Couldn’t create your vault. Try again.');
    }
    if (!mounted) return;
    final failure = err;
    if (failure != null) {
      setState(() {
        _loading = false;
        _emailErr = failure.message;
      });
      _shake.currentState?.shake();
      return;
    }
    nav.popUntil((r) => r.isFirst);
  }

  void _clear(void Function() f) => setState(f);

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return AnnotatedRegion<SystemUiOverlayStyle>(
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
                            error: _nameErr,
                            onChanged: (_) => _clear(() => _nameErr = null),
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
                            error: _emailErr,
                            onChanged: (_) => _clear(() => _emailErr = null),
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
                                obscure: _obscure,
                                action: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                error: _passErr,
                                onChanged: (_) => _clear(() => _passErr = null),
                                trailing: [
                                  EyeButton(
                                    obscured: _obscure,
                                    onTap: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              StrengthMeter(password: _pass.text),
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
                            obscure: _obscure,
                            action: TextInputAction.done,
                            error: _confirmErr,
                            onSubmitted: (_) => _submit(),
                            onChanged: (_) => _clear(() => _confirmErr = null),
                            trailing: [
                              AnimatedScale(
                                scale: _matches ? 1 : 0,
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
                          value: _agree,
                          onChanged: (v) => setState(() => _agree = v),
                        ),
                        const SizedBox(height: 14),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 260),
                          child: PrimaryButton(
                            label: 'Create account',
                            loading: _loading,
                            onTap: _submit,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: InlineLink(
                            prefix: 'Already have an account? ',
                            link: 'Log in',
                            onTap: () => Navigator.of(
                              context,
                            ).pushReplacement(fusionRoute(const LoginScreen())),
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
