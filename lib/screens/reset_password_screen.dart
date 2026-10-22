import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../core/theme/theme.dart';
import '../core/widgets/components.dart';
import '../core/widgets/feedback.dart';
import '../core/widgets/icons.dart';
import '../core/widgets/motion.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _code = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _shake = GlobalKey<ShakeState>();
  Timer? _timer;
  int _seconds = 60;
  bool _obscure = true;
  bool _loading = false;
  String? _codeErr, _passErr, _confirmErr;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _resend() {
    final res = context.read<AuthService>().requestReset(widget.email);
    if (res.code == null) return;
    showCodeBanner(Navigator.of(context).overlay!, res.code!);
    setState(() {
      _code.clear();
      _codeErr = null;
      _startTimer();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _codeErr = _code.text.length != 6 ? 'Enter all 6 digits' : null;
      _passErr = _pass.text.length < 8 ? 'Use at least 8 characters' : null;
      _confirmErr = _confirm.text != _pass.text || _confirm.text.isEmpty
          ? 'Passwords don’t match'
          : null;
    });
    if (_codeErr != null || _passErr != null || _confirmErr != null) {
      HapticFeedback.heavyImpact();
      _shake.currentState?.shake();
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    AuthError? err;
    try {
      err = await auth.resetPassword(_code.text, _pass.text);
    } catch (_) {
      err = (
        field: 'code',
        message: 'Couldn’t save the new password. Try again.',
      );
    }
    if (!mounted) return;
    final failure = err;
    if (failure != null) {
      setState(() {
        _loading = false;
        _codeErr = failure.message;
      });
      HapticFeedback.heavyImpact();
      _shake.currentState?.shake();
      return;
    }
    nav.popUntil((r) => r.isFirst);
    showFusionToastOn(messenger, 'Password updated. Log in with your new one.');
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final m = (_seconds ~/ 60).toString();
    final s = (_seconds % 60).toString().padLeft(2, '0');

    return AnnotatedRegion<SystemUiOverlayStyle>(
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
                              style: FT.body(16, color: fc.muted, height: 1.5),
                              children: [
                                const TextSpan(
                                  text: 'We sent a 6-digit code for ',
                                ),
                                TextSpan(
                                  text: widget.email,
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
                                error: _codeErr != null,
                                onCompleted: () {
                                  if (_codeErr != null) {
                                    setState(() => _codeErr = null);
                                  }
                                },
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                alignment: Alignment.topLeft,
                                child: _codeErr == null
                                    ? const SizedBox(width: double.infinity)
                                    : Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          _codeErr!,
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
                                    duration: const Duration(milliseconds: 250),
                                    transitionBuilder: (c, a) =>
                                        FadeTransition(opacity: a, child: c),
                                    child: _seconds > 0
                                        ? Padding(
                                            key: const ValueKey('wait'),
                                            padding: const EdgeInsets.symmetric(
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
                                            onTap: _resend,
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
                                obscure: _obscure,
                                action: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                error: _passErr,
                                onChanged: (_) =>
                                    setState(() => _passErr = null),
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
                        const SizedBox(height: 16),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 220),
                          child: FusionField(
                            label: 'Confirm new password',
                            controller: _confirm,
                            icon: FIcons.lock,
                            hint: 'Type it once more',
                            obscure: _obscure,
                            action: TextInputAction.done,
                            error: _confirmErr,
                            onSubmitted: (_) => _submit(),
                            onChanged: (_) =>
                                setState(() => _confirmErr = null),
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
                  loading: _loading,
                  onTap: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
