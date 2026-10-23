import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import 'components.dart';
import 'icons.dart';

/// Ink "pill" toast with a lime check — used for copy / save / delete.
/// Its background comes from the theme's `snackBarTheme` (the panel colour):
/// the messenger sits above the app theme, so colours resolve inside the bar.
void showFusionToastOn(
  ScaffoldMessengerState messenger,
  String message, {
  String icon = FIcons.check,
  double bottom = 24,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: EdgeInsets.fromLTRB(20, 0, 20, bottom),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        duration: const Duration(milliseconds: 2200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Builder(
          builder: (context) => Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.fc.lime,
                  shape: BoxShape.circle,
                ),
                child: FIcon(
                  icon,
                  size: 15,
                  stroke: 2.6,
                  color: context.fc.onLime,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: FT.body(
                    14,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

void showFusionToast(
  BuildContext context,
  String message, {
  String icon = FIcons.check,
  double bottom = 24,
}) {
  showFusionToastOn(
    ScaffoldMessenger.of(context),
    message,
    icon: icon,
    bottom: bottom,
  );
}

/// Copies to the clipboard. Secrets are wiped from the clipboard after 45 s.
Future<void> copyToClipboard(
  BuildContext context,
  String value,
  String what, {
  bool secret = false,
  double bottom = 24,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  // Reading the clipboard back on iOS triggers a paste-permission prompt,
  // so the timed clear only runs on Android.
  final autoClear = secret && defaultTargetPlatform == TargetPlatform.android;
  await Clipboard.setData(ClipboardData(text: value));
  HapticFeedback.lightImpact();
  showFusionToastOn(
    messenger,
    autoClear ? '$what copied · clears in 45s' : '$what copied',
    icon: FIcons.copy,
    bottom: bottom,
  );
  if (autoClear) {
    Timer(const Duration(seconds: 45), () async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == value) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }
}

/// With no mail server, the reset code arrives as an in-app notification
/// that slides down from the top of the screen.
void showCodeBanner(OverlayState overlay, String code) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CodeBanner(code: code, onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _CodeBanner extends StatefulWidget {
  const _CodeBanner({required this.code, required this.onDone});

  final String code;
  final VoidCallback onDone;

  @override
  State<_CodeBanner> createState() => _CodeBannerState();
}

class _CodeBannerState extends State<_CodeBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 300),
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _c.forward();
    _timer = Timer(const Duration(seconds: 8), _dismiss);
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    if (mounted) await _c.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final curved = CurvedAnimation(
      parent: _c,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    final spaced = widget.code.split('').join(' ');
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, -1.6),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: _c,
          child: Material(
            color: Colors.transparent,
            child: Semantics(
              liveRegion: true,
              label: 'Fusion reset code ${widget.code}',
              child: GestureDetector(
                onTap: _dismiss,
                onVerticalDragEnd: (_) => _dismiss(),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: fc.panel,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4016142B),
                        blurRadius: 30,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: fc.lime,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: FIcon(FIcons.mail, size: 20, color: fc.onLime),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'FUSION · RESET CODE',
                              style: FT.eyebrow(color: fc.lime),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              spaced,
                              style: FT.mono(
                                22,
                                color: Colors.white,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'now',
                        style: FT.body(12, color: const Color(0xFFB9B6CC)),
                      ),
                    ],
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

/// Bottom-sheet confirmation used for delete / erase.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Keep it',
  String icon = FIcons.trash,
}) async {
  HapticFeedback.mediumImpact();
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: context.fc.scrim,
    isScrollControlled: true,
    builder: (ctx) => _ConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
    ),
  );
  return result ?? false;
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: fc.raised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: fc.line,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 26),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 750),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.rotate(
              angle: (1 - v) * 0.5,
              child: Transform.scale(scale: 0.6 + 0.4 * v, child: child),
            ),
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fc.dangerTint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: FIcon(icon, size: 32, color: fc.danger),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: FT.display(26, spacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: FT.body(15, color: fc.muted, height: 1.5),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: confirmLabel,
            color: fc.danger,
            glow: false,
            onTap: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: cancelLabel,
            color: fc.bg,
            foreground: fc.ink,
            glow: false,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
