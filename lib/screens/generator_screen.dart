import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/password_generator.dart';
import '../theme.dart';
import '../widgets/components.dart';
import '../widgets/feedback.dart';
import '../widgets/icons.dart';
import '../widgets/motion.dart';
import 'home_shell.dart';
import 'login_form_screen.dart';

/// Password generator. As a tab it saves into a new login; in [pickMode]
/// (opened from a form) it returns the chosen password.
class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key, this.pickMode = false, this.onOpenVault});

  final bool pickMode;
  final VoidCallback? onOpenVault;

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen>
    with SingleTickerProviderStateMixin {
  GenOptions _o = const GenOptions();
  late String _pw = generatePassword(_o);
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final CurvedAnimation _spinCurve = CurvedAnimation(
    parent: _spin,
    curve: Curves.easeOutBack,
  );
  bool _copied = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _spinCurve.dispose();
    _spin.dispose();
    _copyTimer?.cancel();
    super.dispose();
  }

  void _regen([GenOptions? o]) {
    setState(() {
      if (o != null) _o = o;
      _pw = generatePassword(_o);
      _copied = false;
    });
  }

  void _onRegenerate() {
    HapticFeedback.selectionClick();
    _spin.forward(from: 0);
    _regen();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _pw));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _toggle(String which) {
    final next = switch (which) {
      'upper' => _o.copyWith(upper: !_o.upper),
      'lower' => _o.copyWith(lower: !_o.lower),
      'numbers' => _o.copyWith(numbers: !_o.numbers),
      _ => _o.copyWith(symbols: !_o.symbols),
    };
    if (next.enabledCount == 0) {
      HapticFeedback.heavyImpact();
      showFusionToast(
        context,
        'Keep at least one character type',
        icon: FIcons.info,
        bottom: widget.pickMode ? 96 : 108,
      );
      return;
    }
    HapticFeedback.selectionClick();
    _regen(next);
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.pickMode)
          Row(
            children: [
              const BackButtonF(),
              const SizedBox(width: 14),
              Text('Generate', style: FT.display(26, spacing: -0.8)),
            ],
          )
        else
          FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Make it unguessable',
                  style: FT.body(14, color: FC.muted),
                ),
                const SizedBox(height: 2),
                Text('Generator', style: FT.display(32, spacing: -1)),
              ],
            ),
          ),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          offset: 24,
          child: _card(),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(delay: const Duration(milliseconds: 120), child: _length()),
        const SizedBox(height: 18),
        FadeSlideIn(
          delay: const Duration(milliseconds: 180),
          child: _include(),
        ),
        if (!widget.pickMode) ...[
          const SizedBox(height: 22),
          FadeSlideIn(
            delay: const Duration(milliseconds: 240),
            child: PrimaryButton(
              label: 'Save this password',
              color: FC.ink,
              glow: false,
              trailingIcon: FIcons.arrowRight,
              onTap: () => Navigator.of(
                context,
              ).push(fusionRoute(LoginFormScreen(initialPassword: _pw))),
            ),
          ),
        ],
      ],
    );

    if (widget.pickMode) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: darkStatusBar,
        child: Scaffold(
          backgroundColor: FC.bg,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: content,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: PrimaryButton(
                    label: 'Use this password',
                    trailingIcon: FIcons.check,
                    onTap: () => Navigator.of(context).pop(_pw),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, navClearance(context)),
        child: content,
      ),
    );
  }

  Widget _card() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: FC.violet,
        child: Stack(
          children: [
            const Positioned(
              right: -50,
              top: -60,
              child: Blob(size: 150, color: Color(0x2EFFFFFF), ring: true),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR NEW PASSWORD',
                    style: FT.body(
                      12,
                      weight: FontWeight.w700,
                      color: FC.lime,
                      spacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 68),
                    child: SizedBox(
                      width: double.infinity,
                      child: ScrambleText(
                        _pw,
                        style: FT.mono(
                          26,
                          weight: FontWeight.w500,
                          height: 1.3,
                          spacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StrengthMeter(password: _pw, onDark: true),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _CardButton(
                          bg: FC.onVioletGlass,
                          semanticLabel: 'Regenerate password',
                          onTap: _onRegenerate,
                          icon: RotationTransition(
                            turns: _spinCurve,
                            child: const FIcon(
                              FIcons.refresh,
                              size: 18,
                              color: Colors.white,
                              stroke: 2.2,
                            ),
                          ),
                          label: Text(
                            'Regenerate',
                            style: FT.body(
                              15,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CardButton(
                          bg: FC.lime,
                          semanticLabel: _copied ? 'Copied' : 'Copy password',
                          onTap: _copy,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (c, a) =>
                                ScaleTransition(scale: a, child: c),
                            child: FIcon(
                              _copied ? FIcons.check : FIcons.copy,
                              key: ValueKey(_copied),
                              size: 18,
                              stroke: 2.2,
                            ),
                          ),
                          label: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (c, a) =>
                                FadeTransition(opacity: a, child: c),
                            child: Text(
                              _copied ? 'Copied' : 'Copy',
                              key: ValueKey(_copied),
                              style: FT.body(15, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _length() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Length',
                style: FT.body(15, weight: FontWeight.w700),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Container(
                key: ValueKey(_o.length),
                constraints: const BoxConstraints(minWidth: 44),
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FC.ink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_o.length}',
                  style: FT.mono(15, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: FC.violet,
            inactiveTrackColor: FC.line,
            thumbColor: FC.violet,
            overlayColor: const Color(0x295B47F5),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            trackShape: const RoundedRectSliderTrackShape(),
            showValueIndicator: ShowValueIndicator.never,
            activeTickMarkColor: Colors.transparent,
            inactiveTickMarkColor: Colors.transparent,
          ),
          child: Slider(
            value: _o.length.toDouble(),
            min: 8,
            max: 40,
            divisions: 32,
            semanticFormatterCallback: (v) => '${v.round()} characters',
            onChanged: (v) {
              final n = v.round();
              if (n != _o.length) {
                HapticFeedback.selectionClick();
                _regen(_o.copyWith(length: n));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _include() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Include', style: FT.body(15, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _OptionTile(
                label: 'Uppercase',
                sample: 'ABC',
                on: _o.upper,
                onTap: () => _toggle('upper'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OptionTile(
                label: 'Lowercase',
                sample: 'abc',
                on: _o.lower,
                onTap: () => _toggle('lower'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _OptionTile(
                label: 'Numbers',
                sample: '123',
                on: _o.numbers,
                onTap: () => _toggle('numbers'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OptionTile(
                label: 'Symbols',
                sample: r'#$&',
                on: _o.symbols,
                onTap: () => _toggle('symbols'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.bg,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.semanticLabel,
  });

  final Color bg;
  final Widget icon;
  final Widget label;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [icon, const SizedBox(width: 8), label],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.sample,
    required this.on,
    required this.onTap,
  });

  final String label;
  final String sample;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: '$label, ${on ? 'on' : 'off'}',
      selected: on,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: on ? FC.violetTint : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? FC.violet : FC.line, width: 1.5),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? FC.violet : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: on ? FC.violet : FC.checkOff,
                  width: 1.5,
                ),
              ),
              child: AnimatedScale(
                scale: on ? 1 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: const FIcon(
                  FIcons.check,
                  size: 14,
                  color: Colors.white,
                  stroke: 3,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: FT.body(14, weight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(sample, style: FT.mono(12, color: FC.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
