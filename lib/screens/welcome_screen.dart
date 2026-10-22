import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/password_generator.dart';
import '../theme.dart';
import '../widgets/components.dart';
import '../widgets/icons.dart';
import '../widgets/motion.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightStatusBar,
      child: Scaffold(
        backgroundColor: fc.violet,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FadeSlideIn(child: FusionWordmark(onDark: true)),
                const SizedBox(height: 16),
                Expanded(child: _Illustration(float: _float)),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 250),
                  child: Text(
                    'One vault.\nEvery password.',
                    style: FT.display(
                      46,
                      color: Colors.white,
                      height: 0.98,
                      spacing: -1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 330),
                  child: Text(
                    'Generate, save and sign in with ease — Fusion keeps every login safe and a tap away.',
                    style: FT.body(16, color: fc.onViolet, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 410),
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: 'Create account',
                        color: fc.lime,
                        foreground: fc.onLime,
                        glow: false,
                        trailingIcon: FIcons.arrowRight,
                        onTap: () => Navigator.of(
                          context,
                        ).push(fusionRoute(const SignUpScreen())),
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'I already have an account',
                        color: Colors.transparent,
                        foreground: Colors.white,
                        borderColor: const Color(0x8CFFFFFF),
                        glow: false,
                        onTap: () => Navigator.of(
                          context,
                        ).push(fusionRoute(const LoginScreen())),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.float});

  final Animation<double> float;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, c) {
          final h = c.maxHeight;
          final w = c.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -110,
                top: -10,
                child: PopIn(
                  delay: const Duration(milliseconds: 80),
                  child: AnimatedBuilder(
                    animation: float,
                    builder: (_, child) => Transform.scale(
                      scale: 1 + 0.035 * math.sin(float.value * 2 * math.pi),
                      child: child,
                    ),
                    child: Blob(size: 300, color: fc.lime),
                  ),
                ),
              ),
              Positioned(
                left: -70,
                top: h * 0.48,
                child: const PopIn(
                  delay: Duration(milliseconds: 160),
                  child: Blob(size: 190, color: Color(0x59FFFFFF), ring: true),
                ),
              ),
              Positioned(
                left: w * 0.5,
                top: 30,
                child: AnimatedBuilder(
                  animation: float,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(
                      0,
                      8 * math.sin(float.value * 2 * math.pi * 2),
                    ),
                    child: child,
                  ),
                  child: const Blob(size: 14, color: Colors.white),
                ),
              ),
              Positioned(
                left: 8,
                top: h * 0.14,
                child: PopIn(
                  delay: const Duration(milliseconds: 220),
                  child: AnimatedBuilder(
                    animation: float,
                    builder: (_, child) {
                      final t = float.value * 2 * math.pi;
                      return Transform.translate(
                        offset: Offset(0, 7 * math.sin(t)),
                        child: Transform.rotate(
                          angle: -0.122 + 0.025 * math.sin(t),
                          child: child,
                        ),
                      );
                    },
                    child: const _VaultCard(),
                  ),
                ),
              ),
              Positioned(
                right: 6,
                top: h * 0.54,
                child: PopIn(
                  delay: const Duration(milliseconds: 340),
                  child: AnimatedBuilder(
                    animation: float,
                    builder: (_, child) {
                      final t = float.value * 2 * math.pi + math.pi;
                      return Transform.translate(
                        offset: Offset(0, 7 * math.sin(t)),
                        child: Transform.rotate(
                          angle: 0.105 + 0.02 * math.sin(t),
                          child: child,
                        ),
                      );
                    },
                    child: const _GeneratedCard(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VaultCard extends StatelessWidget {
  const _VaultCard();

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Container(
      width: 232,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fc.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4016142B),
            blurRadius: 40,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              MonogramTile(
                text: 'Spotify',
                size: 40,
                radius: 13,
                bg: fc.lavender,
                fg: fc.violetDeep,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spotify',
                      style: FT.body(15, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'aanya@example.com',
                      overflow: TextOverflow.ellipsis,
                      style: FT.body(12, color: fc.muted),
                    ),
                  ],
                ),
              ),
              FIcon(FIcons.star, filled: true, color: fc.violet),
            ],
          ),
          const SizedBox(height: 12),
          Text('••••••••••', style: FT.mono(18, spacing: 3)),
        ],
      ),
    );
  }
}

class _GeneratedCard extends StatefulWidget {
  const _GeneratedCard();

  @override
  State<_GeneratedCard> createState() => _GeneratedCardState();
}

class _GeneratedCardState extends State<_GeneratedCard> {
  String _pw = r'k7#Qm!9vRz&2';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2800), (_) {
      if (mounted) {
        setState(() => _pw = generatePassword(const GenOptions(length: 12)));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Container(
      width: 214,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fc.panel,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D16142B),
            blurRadius: 40,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'GENERATED',
            style: FT.body(
              11,
              weight: FontWeight.w700,
              color: fc.lime,
              spacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ScrambleText(
            _pw,
            style: FT.mono(18, color: Colors.white, spacing: 0.5),
            otherColor: Colors.white,
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: fc.lime,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
