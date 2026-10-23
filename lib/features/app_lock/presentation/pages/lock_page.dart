import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/bloc/effects.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/icons.dart';
import '../../../../core/widgets/motion.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/biometric_kind.dart';
import '../biometric_label.dart';
import '../bloc/app_lock_bloc.dart';
import '../cubits/lock_cubit.dart';
import '../widgets/pin_pad.dart';

/// Unlocks the vault with the Fusion PIN or biometrics.
///
/// On launch it is a page of its own and opens the vault. With [resume] it
/// covers whatever the user was doing and goes away when unlocked.
class LockPage extends StatelessWidget {
  const LockPage({super.key, this.resume = false});

  final bool resume;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<LockCubit>(param1: resume),
    child: _LockView(resume: resume),
  );
}

class _LockView extends StatefulWidget {
  const _LockView({required this.resume});

  final bool resume;

  @override
  State<_LockView> createState() => _LockViewState();
}

class _LockViewState extends State<_LockView> {
  final _shake = GlobalKey<ShakeState>();
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<LockCubit>();
    if (!cubit.shouldAutoPrompt()) return;
    // The system sheet can only show while the app is in front.
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) cubit.biometric();
      });
    } else {
      _lifecycle = AppLifecycleListener(
        onResume: () {
          _lifecycle?.dispose();
          _lifecycle = null;
          if (mounted) cubit.biometric();
        },
      );
    }
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  void _onEffect(BuildContext context, LockEffect effect) {
    switch (effect) {
      case LockEffect.wrongPin:
        HapticFeedback.heavyImpact();
        _shake.currentState?.shake();
      case LockEffect.resumeUnlocked:
        context.read<AppLockBloc>().add(const ResumeUnlocked());
    }
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final cubit = context.read<LockCubit>();
    final pin = context.watch<LockCubit>().state;
    final lock = context.watch<AppLockBloc>().state.status;
    final first = context.watch<AuthBloc>().state.firstName;
    final bio = lock.canUseBiometric && !lock.pinLockedOut;
    final bioLabel = lock.kind.label;
    // Violet in light mode; in dark mode a full violet screen glares, so the
    // lock sits on the dark page like the rest of the app.
    final onViolet = Theme.of(context).brightness == Brightness.light;

    return EffectListener<LockCubit, LockEffect>(
      listener: _onEffect,
      child: PopScope(
        canPop: !widget.resume,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: lightStatusBar,
          child: Scaffold(
            backgroundColor: onViolet ? fc.violet : fc.bg,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: box.maxWidth,
                      minHeight: box.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                        child: Column(
                          children: [
                            PopIn(
                              child: FusionLogo(
                                size: 56,
                                left: onViolet ? Colors.white : null,
                              ),
                            ),
                            const SizedBox(height: 22),
                            FadeSlideIn(
                              child: Text(
                                first.isEmpty
                                    ? 'Welcome back'
                                    : 'Welcome back, $first',
                                textAlign: TextAlign.center,
                                style: FT.display(
                                  30,
                                  color: onViolet ? Colors.white : fc.ink,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 60),
                              child: Text(
                                bio
                                    ? 'Enter your PIN or use $bioLabel'
                                    : 'Enter your PIN',
                                textAlign: TextAlign.center,
                                style: FT.body(
                                  15,
                                  color: onViolet ? fc.onViolet : fc.muted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Shake(
                              key: _shake,
                              child: PinDots(
                                filled: pin.entered.length,
                                onDark: onViolet,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 20,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: pin.error == null
                                    ? const SizedBox.shrink()
                                    : Text(
                                        pin.error!,
                                        key: ValueKey(pin.error),
                                        textAlign: TextAlign.center,
                                        style: FT.body(
                                          14,
                                          weight: FontWeight.w700,
                                          color: onViolet ? fc.lime : fc.danger,
                                        ),
                                      ),
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: 20),
                            PinPad(
                              onDark: onViolet,
                              enabled:
                                  !pin.busy && !pin.done && !lock.pinLockedOut,
                              onDigit: cubit.digit,
                              onBackspace: cubit.backspace,
                              onBiometric: bio ? cubit.biometric : null,
                              biometricLabel: bioLabel,
                              biometricIcon: lock.kind == BiometricKind.face
                                  ? FIcons.faceId
                                  : FIcons.fingerprint,
                            ),
                            const SizedBox(height: 8),
                            _UnderlinedLink(
                              'Use master password instead',
                              color: onViolet ? Colors.white : fc.violetText,
                              onTap: cubit.useMasterPassword,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [TextLink] with an underline and a chosen colour, so it also reads on
/// the violet background where violet text would vanish.
class _UnderlinedLink extends StatelessWidget {
  const _UnderlinedLink(this.text, {required this.color, required this.onTap});

  final String text;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: text,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text(
          text,
          style: FT
              .body(14, weight: FontWeight.w700, color: color)
              .copyWith(
                decoration: TextDecoration.underline,
                decorationColor: color,
              ),
        ),
      ),
    );
  }
}
