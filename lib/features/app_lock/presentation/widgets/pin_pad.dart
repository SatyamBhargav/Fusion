import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/icons.dart';
import '../../../../core/widgets/motion.dart';
import '../../domain/entities/app_lock_status.dart';

/// The row of dots above the keypad showing how many digits are in.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.filled,
    this.length = AppLockStatus.pinLength,
    this.onDark = false,
    this.error = false,
  });

  final int filled;
  final int length;
  final bool onDark;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final on = error && !onDark
        ? fc.danger
        : onDark
        ? Colors.white
        : fc.violet;
    final off = onDark ? const Color(0x73FFFFFF) : fc.line;
    return Semantics(
      label: '$filled of $length digits entered',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutBack,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: i < filled ? 16 : 14,
              height: i < filled ? 16 : 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? on : Colors.transparent,
                border: Border.all(color: i < filled ? on : off, width: 2),
              ),
            ),
        ],
      ),
    );
  }
}

/// A 3×4 numeric keypad: digits, backspace and an optional biometric key.
/// Drawn without a text field so no system keyboard ever appears.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.biometricLabel = 'biometrics',
    this.biometricIcon = FIcons.fingerprint,
    this.enabled = true,
    this.onDark = false,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;
  final String biometricLabel;
  final String biometricIcon;
  final bool enabled;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    Widget digit(String d) => _PadKey(
      label: d,
      onDark: onDark,
      onTap: enabled ? () => onDigit(d) : null,
      child: Text(
        d,
        style: FT.display(
          28,
          weight: FontWeight.w700,
          spacing: 0,
          color: onDark ? Colors.white : context.fc.ink,
        ),
      ),
    );

    Widget row(List<Widget> keys) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys,
      ),
    );

    final iconColor = onDark ? Colors.white : context.fc.ink;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row([digit('1'), digit('2'), digit('3')]),
            row([digit('4'), digit('5'), digit('6')]),
            row([digit('7'), digit('8'), digit('9')]),
            row([
              if (onBiometric != null)
                _PadKey(
                  label: 'Use $biometricLabel',
                  plain: true,
                  onDark: onDark,
                  onTap: enabled ? onBiometric : null,
                  child: FIcon(biometricIcon, size: 30, color: iconColor),
                )
              else
                const SizedBox(width: _PadKey.size, height: _PadKey.size),
              digit('0'),
              _PadKey(
                label: 'Delete',
                plain: true,
                onDark: onDark,
                onTap: enabled ? onBackspace : null,
                child: FIcon(FIcons.backspace, size: 26, color: iconColor),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({
    required this.label,
    required this.child,
    required this.onDark,
    this.onTap,
    this.plain = false,
  });

  static const double size = 72;

  final String label;
  final Widget child;
  final bool onDark;
  final VoidCallback? onTap;

  /// Icon keys sit on the page without a filled circle.
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Pressable(
      semanticLabel: label,
      scale: 0.9,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: plain
            ? null
            : BoxDecoration(
                shape: BoxShape.circle,
                color: onDark ? const Color(0x1FFFFFFF) : fc.surface,
                border: onDark ? null : Border.all(color: fc.line, width: 1.5),
              ),
        child: child,
      ),
    );
  }
}
