import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/components.dart';
import '../widgets/icons.dart';
import '../widgets/motion.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _shake = GlobalKey<ShakeState>();
  bool _obscure = true;
  bool _loading = false;
  String? _emailError;
  String? _passError;

  @override
  void initState() {
    super.initState();
    final saved = context.read<AuthService>().email;
    if (saved != null) _email.text = saved;
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _fail() {
    HapticFeedback.heavyImpact();
    _shake.currentState?.shake();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _emailError = looksLikeEmail(_email.text)
          ? null
          : 'Enter the email you signed up with';
      _passError = _pass.text.isEmpty ? 'Enter your master password' : null;
    });
    if (_emailError != null || _passError != null) {
      _fail();
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final nav = Navigator.of(context);
    AuthError? err;
    try {
      err = await auth.login(_email.text, _pass.text);
    } catch (_) {
      err = (field: 'password', message: 'Something went wrong. Try again.');
    }
    if (!mounted) return;
    final failure = err;
    if (failure != null) {
      setState(() {
        _loading = false;
        if (failure.field == 'email') {
          _emailError = failure.message;
        } else {
          _passError = failure.message;
        }
      });
      _fail();
      return;
    }
    nav.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final auth = context.watch<AuthService>();
    final canPop = Navigator.of(context).canPop();
    final first = auth.firstName;

    return AnnotatedRegion<SystemUiOverlayStyle>(
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
                            error: _emailError,
                            onChanged: (_) {
                              if (_emailError != null) {
                                setState(() => _emailError = null);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 180),
                          child: FusionField(
                            label: 'Master password',
                            controller: _pass,
                            icon: FIcons.lock,
                            obscure: _obscure,
                            action: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            error: _passError,
                            onSubmitted: (_) => _submit(),
                            onChanged: (_) {
                              if (_passError != null) {
                                setState(() => _passError = null);
                              }
                            },
                            trailing: [
                              EyeButton(
                                obscured: _obscure,
                                onTap: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextLink(
                            'Forgot password?',
                            onTap: () => Navigator.of(
                              context,
                            ).push(fusionRoute(const ForgotPasswordScreen())),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 240),
                          child: PrimaryButton(
                            label: 'Log in',
                            trailingIcon: FIcons.arrowRight,
                            loading: _loading,
                            onTap: _submit,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (!auth.hasAccount)
                          Center(
                            child: InlineLink(
                              prefix: 'New to Fusion? ',
                              link: 'Create an account',
                              onTap: () =>
                                  Navigator.of(context).pushReplacement(
                                    fusionRoute(const SignUpScreen()),
                                  ),
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
