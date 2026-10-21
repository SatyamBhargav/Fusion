import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Fades + rises a child into place, optionally after a delay (staggering).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
    this.duration = const Duration(milliseconds: 520),
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _a.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - _a.value) * widget.offset),
          child: child,
        ),
      ),
    );
  }
}

/// Springy scale-in used for decorative shapes and illustrations.
class PopIn extends StatefulWidget {
  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 750),
    this.from = 0.6,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double from;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutBack,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.5, curve: Curves.easeOut),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _fade.value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: widget.from + (1 - widget.from) * _scale.value,
          child: child,
        ),
      ),
    );
  }
}

/// Horizontal shake for errors. Trigger with `GlobalKey<ShakeState>`.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.child});

  final Widget child;

  @override
  State<Shake> createState() => ShakeState();
}

class ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  void shake() => _c.forward(from: 0);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final t = _c.value;
        final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

/// Tap target that squishes slightly while pressed.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
    this.semanticLabel,
    this.selected,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? semanticLabel;
  final bool? selected;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      selected: widget.selected,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Password text that "decodes" from random glyphs into the real value
/// whenever [text] changes. Letters and other characters get their own colours.
class ScrambleText extends StatefulWidget {
  const ScrambleText(
    this.text, {
    super.key,
    required this.style,
    this.letterColor = Colors.white,
    this.otherColor = FC.lime,
    this.duration = const Duration(milliseconds: 650),
  });

  final String text;
  final TextStyle style;
  final Color letterColor;
  final Color otherColor;
  final Duration duration;

  @override
  State<ScrambleText> createState() => _ScrambleTextState();
}

class _ScrambleTextState extends State<ScrambleText>
    with SingleTickerProviderStateMixin {
  static const _glyphs =
      r'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%&*?+=';
  static final _letter = RegExp('[A-Za-z]');
  final _rng = math.Random();
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );

  @override
  void didUpdateWidget(covariant ScrambleText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.text,
      liveRegion: true,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final done = _c.value >= 1;
            final settled =
                (Curves.easeOut.transform(_c.value) * widget.text.length)
                    .floor();
            final spans = <TextSpan>[];
            for (var i = 0; i < widget.text.length; i++) {
              final real = done || i < settled;
              final ch = real
                  ? widget.text[i]
                  : _glyphs[_rng.nextInt(_glyphs.length)];
              final isLetter = _letter.hasMatch(ch);
              final base = isLetter ? widget.letterColor : widget.otherColor;
              spans.add(
                TextSpan(
                  text: ch,
                  style: TextStyle(color: real ? base : base.withAlpha(120)),
                ),
              );
            }
            return Text.rich(TextSpan(children: spans), style: widget.style);
          },
        ),
      ),
    );
  }
}
