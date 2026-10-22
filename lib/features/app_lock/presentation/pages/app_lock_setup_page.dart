import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/bloc/effects.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/icons.dart';
import '../../../../core/widgets/motion.dart';
import '../../domain/entities/biometric_kind.dart';
import '../biometric_label.dart';
import '../bloc/app_lock_bloc.dart';
import '../cubits/app_lock_setup_cubit.dart';
import '../widgets/pin_pad.dart';

/// Sets the Fusion PIN. Right after the first login this is mandatory (no
/// back, no skip) and ends with an optional offer to turn on biometrics.
/// With [change] it is opened from Settings and checks the current PIN first.
class AppLockSetupPage extends StatelessWidget {
  const AppLockSetupPage({super.key, this.change = false});

  final bool change;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<AppLockSetupCubit>(param1: change),
    child: _AppLockSetupView(change: change),
  );
}

class _AppLockSetupView extends StatefulWidget {
  const _AppLockSetupView({required this.change});

  final bool change;

  @override
  State<_AppLockSetupView> createState() => _AppLockSetupViewState();
}

class _AppLockSetupViewState extends State<_AppLockSetupView> {
  final _shake = GlobalKey<ShakeState>();

  void _onEffect(BuildContext context, AppLockSetupEffect effect) {
    switch (effect) {
      case AppLockSetupEffect.failed:
        HapticFeedback.heavyImpact();
        _shake.currentState?.shake();
      case AppLockSetupEffect.changed:
        final messenger = ScaffoldMessenger.of(context);
        context.pop();
        showFusionToastOn(messenger, 'PIN changed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final setup = context.watch<AppLockSetupCubit>().state;
    final lock = context.watch<AppLockBloc>().state.status;
    final bioLabel = lock.kind.label;
    final (title, subtitle) = switch (setup.step) {
      SetupStep.current => (
        'Enter your current PIN',
        'Check it’s you before setting a new one.',
      ),
      SetupStep.create => (
        'Create a PIN',
        'You’ll use these 6 digits to open Fusion every time.',
      ),
      SetupStep.confirm => (
        'Confirm your PIN',
        'Enter the same 6 digits again.',
      ),
      SetupStep.biometric => (
        'Use $bioLabel?',
        'Open Fusion with $bioLabel instead of typing your PIN. '
            'Your PIN still works as a backup.',
      ),
    };
    final lockedOut = setup.step == SetupStep.current && lock.pinLockedOut;

    return EffectListener<AppLockSetupCubit, AppLockSetupEffect>(
      listener: _onEffect,
      child: PopScope(
        canPop: widget.change,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: statusBarFor(context),
          child: Scaffold(
            backgroundColor: fc.bg,
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
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (widget.change) ...[
                                  const BackButtonF(),
                                  const SizedBox(width: 14),
                                ],
                                const FusionWordmark(),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Container(
                              width: 52,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: fc.violetTint,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: FIcon(
                                setup.step == SetupStep.biometric
                                    ? (lock.kind == BiometricKind.face
                                          ? FIcons.faceId
                                          : FIcons.fingerprint)
                                    : FIcons.lock,
                                size: 24,
                                color: fc.violet,
                              ),
                            ),
                            const SizedBox(height: 18),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Column(
                                key: ValueKey(setup.step),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: FT.display(
                                      32,
                                      spacing: -1,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    subtitle,
                                    style: FT.body(
                                      15,
                                      color: fc.muted,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (setup.step == SetupStep.biometric)
                              ..._biometricChoice(setup, bioLabel)
                            else
                              ..._pinEntry(setup, lockedOut),
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

  List<Widget> _pinEntry(AppLockSetupState setup, bool lockedOut) {
    final fc = context.fc;
    final cubit = context.read<AppLockSetupCubit>();
    return [
      const SizedBox(height: 32),
      Center(
        child: Shake(
          key: _shake,
          child: PinDots(
            filled: setup.entered.length,
            error: setup.error != null,
          ),
        ),
      ),
      const SizedBox(height: 14),
      _ErrorLine(setup.error, color: fc.danger),
      const Spacer(),
      const SizedBox(height: 16),
      Center(
        child: PinPad(
          enabled: !setup.busy && !lockedOut,
          onDigit: cubit.digit,
          onBackspace: cubit.backspace,
        ),
      ),
    ];
  }

  List<Widget> _biometricChoice(AppLockSetupState setup, String bioLabel) {
    final fc = context.fc;
    final cubit = context.read<AppLockSetupCubit>();
    return [
      const SizedBox(height: 14),
      _ErrorLine(setup.error, color: fc.danger, center: false),
      const Spacer(),
      PrimaryButton(
        label: 'Use $bioLabel',
        loading: setup.busy,
        onTap: () => cubit.enableBiometric(bioLabel),
      ),
      const SizedBox(height: 4),
      Center(
        child: TextLink(
          'Not now',
          onTap: () {
            if (!setup.busy) cubit.skipBiometric();
          },
        ),
      ),
    ];
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.message, {required this.color, this.center = true});

  final String? message;
  final Color color;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final m = message;
    return SizedBox(
      height: 20,
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: m == null
            ? const SizedBox.shrink()
            : Text(
                m,
                key: ValueKey(m),
                textAlign: center ? TextAlign.center : TextAlign.start,
                style: FT.body(14, weight: FontWeight.w700, color: color),
              ),
      ),
    );
  }
}
