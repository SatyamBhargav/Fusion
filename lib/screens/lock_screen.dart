import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/app_lock_controller.dart';
import '../services/auth_service.dart';
import '../services/biometric_auth.dart';
import '../services/vault_store.dart';
import '../core/theme/theme.dart';
import '../core/widgets/components.dart';
import '../core/widgets/icons.dart';
import '../core/widgets/motion.dart';
import '../features/app_lock/presentation/widgets/pin_pad.dart';

const lockRouteName = '/app-lock';

/// The lock shown when the app comes back from the background. Opaque and
/// instant, so the first frame after returning is already locked. Completes
/// with true only when the user actually unlocked.
Route<bool> lockRoute() => PageRouteBuilder<bool>(
  settings: const RouteSettings(name: lockRouteName),
  transitionDuration: Duration.zero,
  reverseTransitionDuration: const Duration(milliseconds: 220),
  pageBuilder: (_, __, ___) => const LockScreen(resume: true),
  transitionsBuilder: (_, animation, __, child) =>
      FadeTransition(opacity: animation, child: child),
);

/// Unlocks the vault with the Fusion PIN or biometrics.
///
/// On launch it is the root screen and opens the vault through
/// [AuthService.unlockWithAppLock]. With [resume] it sits on top of whatever
/// the user was doing and simply pops when unlocked.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, this.resume = false});

  final bool resume;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _shake = GlobalKey<ShakeState>();
  AppLifecycleListener? _lifecycle;
  String _entered = '';
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final lock = context.read<AppLockController>();
    if (lock.pinLockedOut) _error = _lockedOutMessage;
    if (lock.consumeSkipAutoPrompt()) return;
    if (!lock.canUseBiometric || lock.pinLockedOut) return;
    // The system sheet can only show while the app is in front.
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _biometric());
    } else {
      _lifecycle = AppLifecycleListener(
        onResume: () {
          _lifecycle?.dispose();
          _lifecycle = null;
          _biometric();
        },
      );
    }
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  static const _lockedOutMessage =
      'Too many attempts. Use your master password.';

  void _unlocked() {
    if (_done) return;
    _done = true;
    if (widget.resume) {
      Navigator.of(context).pop(true);
    } else {
      context.read<AuthService>().unlockWithAppLock();
    }
  }

  Future<void> _biometric() async {
    if (!mounted || _busy || _done) return;
    final lock = context.read<AppLockController>();
    final ok = await lock.tryBiometric('Unlock your Fusion vault');
    if (ok && mounted) _unlocked();
  }

  void _digit(String d) {
    if (_busy || _done || _entered.length >= AppLockController.pinLength) {
      return;
    }
    setState(() {
      _entered += d;
      _error = null;
    });
    if (_entered.length == AppLockController.pinLength) _check();
  }

  void _backspace() {
    if (_busy || _entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    final lock = context.read<AppLockController>();
    final ok = await lock.verifyPin(_entered);
    if (!mounted) return;
    if (ok) {
      _unlocked();
      return;
    }
    HapticFeedback.heavyImpact();
    _shake.currentState?.shake();
    setState(() {
      _busy = false;
      _entered = '';
      final left = lock.attemptsLeft;
      _error = lock.pinLockedOut
          ? _lockedOutMessage
          : 'Wrong PIN · $left ${left == 1 ? 'try' : 'tries'} left';
    });
  }

  void _useMasterPassword() {
    if (_done) return;
    _done = true;
    final lock = context.read<AppLockController>();
    if (widget.resume) {
      final vault = context.read<VaultStore>();
      final auth = context.read<AuthService>();
      Navigator.of(context).popUntil((r) => r.isFirst);
      vault.reset();
      auth.logout();
    }
    lock.requestMasterPassword();
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final lock = context.watch<AppLockController>();
    final first = context.watch<AuthService>().firstName;
    final bio = lock.canUseBiometric && !lock.pinLockedOut;
    final bioLabel = lock.biometricKind.label;
    // Violet in light mode; in dark mode a full violet screen glares, so the
    // lock sits on the dark page like the rest of the app.
    final onViolet = Theme.of(context).brightness == Brightness.light;

    return PopScope(
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
                              filled: _entered.length,
                              onDark: onViolet,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 20,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _error == null
                                  ? const SizedBox.shrink()
                                  : Text(
                                      _error!,
                                      key: ValueKey(_error),
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
                            enabled: !_busy && !_done && !lock.pinLockedOut,
                            onDigit: _digit,
                            onBackspace: _backspace,
                            onBiometric: bio ? _biometric : null,
                            biometricLabel: bioLabel,
                            biometricIcon:
                                lock.biometricKind == BiometricKind.face
                                ? FIcons.faceId
                                : FIcons.fingerprint,
                          ),
                          const SizedBox(height: 8),
                          _UnderlinedLink(
                            'Use master password instead',
                            color: onViolet ? Colors.white : fc.violetText,
                            onTap: _useMasterPassword,
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
