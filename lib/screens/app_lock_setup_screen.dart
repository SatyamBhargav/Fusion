import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/app_lock_controller.dart';
import '../services/auth_service.dart';
import '../services/biometric_auth.dart';
import '../core/theme/theme.dart';
import '../core/widgets/components.dart';
import '../core/widgets/feedback.dart';
import '../core/widgets/icons.dart';
import '../core/widgets/motion.dart';
import '../features/app_lock/presentation/widgets/pin_pad.dart';

enum _Step { current, create, confirm, biometric }

/// Sets the Fusion PIN. Right after the first login this is mandatory (no
/// back, no skip) and ends with an optional offer to turn on biometrics.
/// With [change] it is pushed from Settings and checks the current PIN first.
class AppLockSetupScreen extends StatefulWidget {
  const AppLockSetupScreen({super.key, this.change = false});

  final bool change;

  @override
  State<AppLockSetupScreen> createState() => _AppLockSetupScreenState();
}

class _AppLockSetupScreenState extends State<AppLockSetupScreen> {
  final _shake = GlobalKey<ShakeState>();
  late _Step _step;
  String _entered = '';
  String _first = '';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // A session opened with the master password may replace a forgotten PIN.
    final checkOld =
        widget.change && !context.read<AuthService>().passwordVerified;
    _step = checkOld ? _Step.current : _Step.create;
  }

  void _fail(String message) {
    HapticFeedback.heavyImpact();
    _shake.currentState?.shake();
    setState(() {
      _busy = false;
      _entered = '';
      _error = message;
    });
  }

  void _digit(String d) {
    if (_busy || _entered.length >= AppLockController.pinLength) return;
    setState(() {
      _entered += d;
      _error = null;
    });
    if (_entered.length == AppLockController.pinLength) _submit();
  }

  void _backspace() {
    if (_busy || _entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _submit() async {
    final lock = context.read<AppLockController>();
    final pin = _entered;
    switch (_step) {
      case _Step.current:
        setState(() => _busy = true);
        final ok = await lock.verifyPin(pin);
        if (!mounted) return;
        if (!ok) {
          final left = lock.attemptsLeft;
          _fail(
            lock.pinLockedOut
                ? 'Too many attempts. Use your master password.'
                : 'Wrong PIN · $left ${left == 1 ? 'try' : 'tries'} left',
          );
          return;
        }
        setState(() {
          _busy = false;
          _entered = '';
          _step = _Step.create;
        });
      case _Step.create:
        setState(() {
          _first = pin;
          _entered = '';
          _step = _Step.confirm;
        });
      case _Step.confirm:
        if (pin != _first) {
          _first = '';
          _step = _Step.create;
          _fail('PINs didn’t match. Try again.');
          return;
        }
        if (!widget.change && lock.biometricKind != BiometricKind.none) {
          setState(() {
            _entered = '';
            _step = _Step.biometric;
          });
          return;
        }
        await _finish(biometric: false);
      case _Step.biometric:
        break;
    }
  }

  Future<void> _enableBiometric() async {
    final lock = context.read<AppLockController>();
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await lock.confirmBiometric('Turn on biometric unlock');
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'Couldn’t verify ${lock.biometricKind.label}. Try again.';
      });
      return;
    }
    await _finish(biometric: true);
  }

  /// Saves the PIN last: once it exists the app moves on to the vault.
  Future<void> _finish({required bool biometric}) async {
    setState(() => _busy = true);
    final lock = context.read<AppLockController>();
    final nav = Navigator.of(context);
    final route = ModalRoute.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (biometric) await lock.setBiometric(true);
    await lock.setPin(_first);
    if (!widget.change || !mounted || route == null) return;
    closeRoute(nav, route);
    showFusionToastOn(messenger, 'PIN changed');
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final lock = context.watch<AppLockController>();
    final bioLabel = lock.biometricKind.label;
    final (title, subtitle) = switch (_step) {
      _Step.current => (
        'Enter your current PIN',
        'Check it’s you before setting a new one.',
      ),
      _Step.create => (
        'Create a PIN',
        'You’ll use these 6 digits to open Fusion every time.',
      ),
      _Step.confirm => ('Confirm your PIN', 'Enter the same 6 digits again.'),
      _Step.biometric => (
        'Use $bioLabel?',
        'Open Fusion with $bioLabel instead of typing your PIN. '
            'Your PIN still works as a backup.',
      ),
    };
    final lockedOut = _step == _Step.current && lock.pinLockedOut;

    return PopScope(
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
                              _step == _Step.biometric
                                  ? (lock.biometricKind == BiometricKind.face
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
                              key: ValueKey(_step),
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
                          if (_step == _Step.biometric)
                            ..._biometricChoice(bioLabel)
                          else
                            ..._pinEntry(lockedOut),
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
    );
  }

  List<Widget> _pinEntry(bool lockedOut) {
    final fc = context.fc;
    return [
      const SizedBox(height: 32),
      Center(
        child: Shake(
          key: _shake,
          child: PinDots(filled: _entered.length, error: _error != null),
        ),
      ),
      const SizedBox(height: 14),
      _ErrorLine(_error, color: fc.danger),
      const Spacer(),
      const SizedBox(height: 16),
      Center(
        child: PinPad(
          enabled: !_busy && !lockedOut,
          onDigit: _digit,
          onBackspace: _backspace,
        ),
      ),
    ];
  }

  List<Widget> _biometricChoice(String bioLabel) {
    final fc = context.fc;
    return [
      const SizedBox(height: 14),
      _ErrorLine(_error, color: fc.danger, center: false),
      const Spacer(),
      PrimaryButton(
        label: 'Use $bioLabel',
        loading: _busy,
        onTap: _enableBiometric,
      ),
      const SizedBox(height: 4),
      Center(
        child: TextLink(
          'Not now',
          onTap: () {
            if (!_busy) _finish(biometric: false);
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
