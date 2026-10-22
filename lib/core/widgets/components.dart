import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/password_generator.dart';
import '../theme/theme.dart';
import '../utils/utils.dart';
import 'icons.dart';
import 'motion.dart';

// ───────────────────────────── Brand ─────────────────────────────

class FusionLogo extends StatelessWidget {
  const FusionLogo({
    super.key,
    this.size = 34,
    this.left,
    this.right,
    this.lens,
  });

  final double size;
  final Color? left;
  final Color? right;
  final Color? lens;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return CustomPaint(
      size: Size.square(size),
      painter: _LogoPainter(
        left ?? fc.violet,
        right ?? fc.lime,
        lens ?? fc.onLime,
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.left, this.right, this.lens);

  final Color left;
  final Color right;
  final Color lens;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    final a = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(15 * s, 20 * s), radius: 12 * s),
      );
    final b = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(25 * s, 20 * s), radius: 12 * s),
      );
    canvas.drawPath(a, Paint()..color = left);
    canvas.drawPath(b, Paint()..color = right);
    canvas.drawPath(
      Path.combine(PathOperation.intersect, a, b),
      Paint()..color = lens,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.left != left || old.right != right || old.lens != lens;
}

class FusionWordmark extends StatelessWidget {
  const FusionWordmark({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Semantics(
      label: 'Fusion',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FusionLogo(size: 34, left: onDark ? Colors.white : fc.violet),
            const SizedBox(width: 10),
            Text(
              'fusion',
              style: FT.display(
                23,
                color: onDark ? Colors.white : fc.ink,
                spacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Blob extends StatelessWidget {
  const Blob({
    super.key,
    required this.size,
    required this.color,
    this.ring = false,
  });

  final double size;
  final Color color;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ring ? null : color,
        border: ring ? Border.all(color: color, width: 2) : null,
      ),
    );
  }
}

// ───────────────────────────── Buttons ─────────────────────────────

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.color,
    this.foreground = Colors.white,
    this.trailingIcon,
    this.leadingIcon,
    this.loading = false,
    this.glow = true,
    this.borderColor,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color foreground;
  final String? trailingIcon;
  final String? leadingIcon;
  final bool loading;
  final bool glow;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final enabled = onTap != null && !loading;
    return AnimatedOpacity(
      opacity: onTap == null ? 0.45 : 1,
      duration: const Duration(milliseconds: 200),
      child: Pressable(
        onTap: enabled ? onTap : null,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color ?? fc.violet,
            borderRadius: BorderRadius.circular(18),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1.5)
                : null,
            boxShadow: glow && onTap != null
                ? const [
                    BoxShadow(
                      color: Color(0x475B47F5),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
            child: loading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: foreground,
                    ),
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leadingIcon != null) ...[
                        FIcon(
                          leadingIcon!,
                          size: 18,
                          color: foreground,
                          stroke: 2.2,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: FT.body(
                          16,
                          weight: FontWeight.w700,
                          color: foreground,
                        ),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 8),
                        FIcon(
                          trailingIcon!,
                          size: 20,
                          color: foreground,
                          stroke: 2.2,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.bg,
    this.fg,
    this.bordered = true,
    this.size = 44,
    this.radius = 14,
    this.iconSize = 20,
    this.stroke = 2.2,
  });

  final String icon;
  final String label;
  final VoidCallback? onTap;
  final Color? bg;
  final Color? fg;
  final bool bordered;
  final double size;
  final double radius;
  final double iconSize;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      scale: 0.9,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg ?? fc.surface,
          borderRadius: BorderRadius.circular(radius),
          border: bordered ? Border.all(color: fc.line, width: 1.5) : null,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: FIcon(
            icon,
            key: ValueKey(icon),
            size: iconSize,
            color: fg ?? fc.ink,
            stroke: stroke,
          ),
        ),
      ),
    );
  }
}

class BackButtonF extends StatelessWidget {
  const BackButtonF({
    super.key,
    this.icon = FIcons.back,
    this.label = 'Back',
    this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SquareIconButton(
      icon: icon,
      label: label,
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
    );
  }
}

class EyeButton extends StatelessWidget {
  const EyeButton({super.key, required this.obscured, required this.onTap});

  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return SquareIconButton(
      icon: obscured ? FIcons.eye : FIcons.eyeOff,
      label: obscured ? 'Show password' : 'Hide password',
      onTap: onTap,
      bg: Colors.transparent,
      fg: fc.muted,
      bordered: false,
      radius: 12,
      stroke: 2,
    );
  }
}

class TextLink extends StatelessWidget {
  const TextLink(this.text, {super.key, required this.onTap, this.size = 14});

  final String text;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Pressable(
      onTap: onTap,
      semanticLabel: text,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style: FT.body(size, weight: FontWeight.w700, color: fc.violet),
        ),
      ),
    );
  }
}

class InlineLink extends StatelessWidget {
  const InlineLink({
    super.key,
    required this.prefix,
    required this.link,
    required this.onTap,
  });

  final String prefix;
  final String link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prefix, style: FT.body(15, color: fc.muted)),
        TextLink(link, onTap: onTap, size: 15),
      ],
    );
  }
}

class GenerateChip extends StatelessWidget {
  const GenerateChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Generate a password',
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: fc.lime,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FIcon(FIcons.sparkle, size: 16, stroke: 2.2, color: fc.onLime),
            const SizedBox(width: 6),
            Text(
              'Generate',
              style: FT.body(14, weight: FontWeight.w700, color: fc.onLime),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Inputs ─────────────────────────────

class FusionField extends StatefulWidget {
  const FusionField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.hint,
    this.obscure = false,
    this.mono = false,
    this.keyboardType,
    this.action,
    this.trailing = const [],
    this.onChanged,
    this.onSubmitted,
    this.error,
    this.maxLines = 1,
    this.autofillHints,
    this.capitalization = TextCapitalization.none,
    this.showLabel = true,
    this.height = 56,
  });

  final String label;
  final TextEditingController controller;
  final String? icon;
  final String? hint;
  final bool obscure;
  final bool mono;
  final TextInputType? keyboardType;
  final TextInputAction? action;
  final List<Widget> trailing;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? error;
  final int maxLines;
  final Iterable<String>? autofillHints;
  final TextCapitalization capitalization;
  final bool showLabel;
  final double height;

  @override
  State<FusionField> createState() => _FusionFieldState();
}

class _FusionFieldState extends State<FusionField> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = _focus.hasFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final hasError = widget.error != null;
    final multiline = widget.maxLines > 1 && !widget.obscure;
    final ring = hasError ? fc.danger : (_focused ? fc.violet : fc.line);
    final glow = hasError ? fc.dangerTint : fc.violetTint;

    final field = Semantics(
      label: widget.label,
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        obscureText: widget.obscure,
        obscuringCharacter: '•',
        keyboardType: multiline ? TextInputType.multiline : widget.keyboardType,
        textInputAction: widget.action,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        maxLines: multiline ? widget.maxLines : 1,
        minLines: multiline ? 2 : 1,
        autofillHints: widget.autofillHints,
        textCapitalization: widget.capitalization,
        autocorrect: !widget.obscure && !widget.mono,
        enableSuggestions: !widget.obscure && !widget.mono,
        cursorColor: fc.violet,
        style: widget.mono
            ? FT.mono(16, weight: FontWeight.w500)
            : FT.body(
                16,
                spacing: widget.obscure ? 2 : null,
                height: multiline ? 1.45 : null,
              ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: widget.hint,
          hintStyle: FT.body(16, color: fc.muted),
        ),
      ),
    );

    final box = GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        constraints: BoxConstraints(minHeight: multiline ? 0 : widget.height),
        padding: EdgeInsets.fromLTRB(
          widget.icon != null ? 16 : 14,
          multiline ? 12 : 0,
          widget.trailing.isEmpty ? 14 : 6,
          multiline ? 12 : 0,
        ),
        decoration: BoxDecoration(
          color: fc.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ring, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: (_focused || hasError) ? glow : glow.withAlpha(0),
              spreadRadius: 4,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: multiline
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              FIcon(
                widget.icon!,
                color: hasError ? fc.danger : (_focused ? fc.violet : fc.icon),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(child: field),
            ...widget.trailing,
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel) ...[
          Text(widget.label, style: FT.label(color: fc.ink2)),
          const SizedBox(height: 7),
        ],
        box,
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: FIcon(FIcons.info, size: 15, color: fc.danger),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.error!,
                          style: FT.body(
                            13,
                            weight: FontWeight.w600,
                            color: fc.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Six-box one-time-code input backed by a single hidden TextField.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.error = false,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final bool error;
  final VoidCallback? onCompleted;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
    widget.controller.addListener(_onText);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onText() {
    _rebuild();
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted?.call();
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_rebuild);
    widget.controller.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final text = widget.controller.text;
    final focused = _focus.hasFocus;
    final boxes = <Widget>[];
    for (var i = 0; i < widget.length; i++) {
      final filled = i < text.length;
      final active =
          focused &&
          (i == text.length ||
              (text.length == widget.length && i == widget.length - 1));
      final border = widget.error
          ? fc.danger
          : active
          ? fc.violet
          : filled
          ? fc.violet.withAlpha(77)
          : fc.line;
      if (i > 0) boxes.add(const SizedBox(width: 8));
      boxes.add(
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fc.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: active ? fc.violetTint : fc.violetTint.withAlpha(0),
                  spreadRadius: 4,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (c, a) => ScaleTransition(
                scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
                child: c,
              ),
              child: Text(
                filled ? text[i] : '',
                key: ValueKey('$i-${filled ? text[i] : ''}'),
                style: FT.mono(22, weight: FontWeight.w500),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: 'Reset code',
      child: GestureDetector(
        onTap: () => _focus.requestFocus(),
        child: Stack(
          children: [
            Row(children: boxes),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  showCursor: false,
                  enableInteractiveSelection: false,
                  style: const TextStyle(color: Colors.transparent),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
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

class StrengthMeter extends StatelessWidget {
  const StrengthMeter({super.key, required this.password, this.onDark = false});

  final String password;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final s = strengthOf(password);

    Color seg(int i) {
      if (i >= s.score) return onDark ? const Color(0x38FFFFFF) : fc.line;
      if (onDark) return fc.lime;
      if (s.score == 1) return fc.danger;
      if (s.score == 2) return fc.fair;
      return fc.violet;
    }

    final labelColor = onDark
        ? Colors.white
        : s.score == 1
        ? fc.danger
        : s.score == 2
        ? fc.fairText
        : fc.violetText;

    return Semantics(
      label: s.label.isEmpty ? null : 'Password strength: ${s.label}',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 260 + i * 70),
                      curve: Curves.easeOutCubic,
                      height: 6,
                      margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: seg(i),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(a),
                  child: c,
                ),
              ),
              child: Text(
                s.label.isEmpty ? ' ' : s.label,
                key: ValueKey(s.label),
                style: FT.body(
                  onDark ? 14 : 13,
                  weight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FusionSwitch extends StatelessWidget {
  const FusionSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Semantics(
      toggled: value,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: SizedBox(
          width: 56,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 52,
              height: 32,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? fc.violet : fc.switchOff,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x3316142B),
                        blurRadius: 3,
                        offset: Offset(0, 1),
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

class FavouriteToggleRow extends StatelessWidget {
  const FavouriteToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
        decoration: BoxDecoration(
          color: fc.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: fc.line, width: 1.5),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: FIcon(
                FIcons.star,
                key: ValueKey(value),
                color: fc.violet,
                filled: value,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: FT.body(15, weight: FontWeight.w700)),
            ),
            FusionSwitch(value: value, onChanged: onChanged, label: label),
          ],
        ),
      ),
    );
  }
}

class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.index,
    required this.labels,
    required this.icons,
    required this.onChanged,
  });

  final int index;
  final List<String> labels;
  final List<String> icons;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: fc.segBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutCubic,
            alignment: Alignment(-1 + 2 * index / (labels.length - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / labels.length,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: fc.raised,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1416142B),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(labels.length, (i) {
              final selected = i == index;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: labels[i],
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (!selected) {
                        HapticFeedback.selectionClick();
                        onChanged(i);
                      }
                    },
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FIcon(
                            icons[i],
                            size: 18,
                            stroke: 2.2,
                            color: selected ? fc.violet : fc.ink2,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: FT.body(
                                15,
                                weight: FontWeight.w700,
                                color: selected ? fc.ink : fc.ink2,
                              ),
                              child: Text(
                                labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Display ─────────────────────────────

class MonogramTile extends StatelessWidget {
  const MonogramTile({
    super.key,
    required this.text,
    this.size = 44,
    this.radius = 14,
    this.fontSize = 18,
    this.bg,
    this.fg,
    this.heroTag,
    this.letter,
  });

  final String text;
  final double size;
  final double radius;
  final double fontSize;
  final Color? bg;
  final Color? fg;
  final Object? heroTag;
  final String? letter;

  @override
  Widget build(BuildContext context) {
    final p = paletteFor(text);
    Widget tile = Material(
      type: MaterialType.transparency,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg ?? p.$1,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Text(
          letter ?? monogramOf(text),
          style: FT.display(fontSize, color: fg ?? p.$2, spacing: 0, height: 1),
        ),
      ),
    );
    if (heroTag != null) tile = Hero(tag: heroTag!, child: tile);
    return ExcludeSemantics(child: tile);
  }
}

class StarButton extends StatefulWidget {
  const StarButton({
    super.key,
    required this.active,
    required this.onTap,
    required this.label,
    this.activeColor,
    this.inactiveColor,
    this.bg = Colors.transparent,
    this.activeBg,
    this.size = 20,
    this.box = 44,
    this.radius = 12,
  });

  final bool active;
  final VoidCallback onTap;
  final String label;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color bg;
  final Color? activeBg;
  final double size;
  final double box;
  final double radius;

  @override
  State<StarButton> createState() => _StarButtonState();
}

class _StarButtonState extends State<StarButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.45,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.45,
        end: 0.88,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.88,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
  ]).animate(_c);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Semantics(
      button: true,
      toggled: widget.active,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          _c.forward(from: 0);
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: widget.box,
          height: widget.box,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.active ? (widget.activeBg ?? widget.bg) : widget.bg,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          child: ScaleTransition(
            scale: _scale,
            child: FIcon(
              FIcons.star,
              size: widget.size,
              filled: widget.active,
              color: widget.active
                  ? (widget.activeColor ?? fc.violet)
                  : (widget.inactiveColor ?? fc.icon),
            ),
          ),
        ),
      ),
    );
  }
}

class CountPill extends StatelessWidget {
  const CountPill(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
      child: Container(
        key: ValueKey(count),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: fc.violetTint,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$count',
          style: FT.body(12, weight: FontWeight.w700, color: fc.violetDeep),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = FIcons.key,
  });

  final String title;
  final String message;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          PopIn(
            child: SizedBox(
              width: 120,
              height: 104,
              child: Stack(
                children: [
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Transform.rotate(
                      angle: -0.14,
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: fc.lime,
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Blob(size: 40, color: fc.violet),
                  ),
                  Positioned(
                    left: 30,
                    top: 30,
                    child: Transform.rotate(
                      angle: -0.14,
                      child: FIcon(icon, size: 48, color: fc.onLime),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: FT.display(21, spacing: -0.4),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: FT.body(15, color: fc.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
