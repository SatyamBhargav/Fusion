import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/vault_store.dart';
import '../theme.dart';
import '../widgets/icons.dart';
import '../widgets/motion.dart';
import 'generator_screen.dart';
import 'login_form_screen.dart';
import 'settings_screen.dart';
import 'vault_screen.dart';

/// Space the floating nav bar takes at the bottom of tab pages.
double navClearance(BuildContext context) =>
    112 + MediaQuery.paddingOf(context).bottom;

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<VaultStore>().load();
    });
  }

  void _go(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = i);
  }

  Widget _page() {
    switch (_tab) {
      case 1:
        return GeneratorScreen(onOpenVault: () => _go(0));
      case 2:
        return const VaultScreen(favouritesOnly: true);
      case 3:
        return const SettingsScreen();
      default:
        return VaultScreen(onSeeFavourites: () => _go(2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarFor(context),
      child: Scaffold(
        backgroundColor: fc.bg,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [
                    // Outgoing tabs must not take part in Hero flights.
                    for (final p in previous)
                      HeroMode(key: p.key, enabled: false, child: p),
                    if (current != null)
                      HeroMode(key: current.key, enabled: true, child: current),
                  ],
                ),
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.02),
                      end: Offset.zero,
                    ).animate(a),
                    child: c,
                  ),
                ),
                child: KeyedSubtree(key: ValueKey(_tab), child: _page()),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 20 + bottom,
              child: FadeSlideIn(
                offset: 40,
                delay: const Duration(milliseconds: 150),
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.0,
                  child: _NavBar(
                    index: _tab,
                    onTab: _go,
                    onAdd: () => Navigator.of(
                      context,
                    ).push(fusionRoute(const LoginFormScreen())),
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

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.index,
    required this.onTab,
    required this.onAdd,
  });

  final int index;
  final ValueChanged<int> onTab;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: fc.raised,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2416142B),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            icon: FIcons.shield,
            label: 'Vault',
            active: index == 0,
            onTap: () => onTab(0),
          ),
          _NavItem(
            icon: FIcons.sparkle,
            label: 'Generate',
            active: index == 1,
            onTap: () => onTab(1),
          ),
          Pressable(
            onTap: onAdd,
            scale: 0.88,
            semanticLabel: 'Save a new login',
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fc.violet,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x595B47F5),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const FIcon(
                FIcons.plus,
                size: 24,
                color: Colors.white,
                stroke: 2.4,
              ),
            ),
          ),
          _NavItem(
            icon: FIcons.star,
            label: 'Starred',
            active: index == 2,
            onTap: () => onTab(2),
          ),
          _NavItem(
            icon: FIcons.sliders,
            label: 'Settings',
            active: index == 3,
            onTap: () => onTab(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      selected: active,
      scale: 0.9,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: active ? 14 : 11),
        decoration: BoxDecoration(
          color: active ? fc.lime : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FIcon(
              icon,
              size: active ? 20 : 22,
              color: active ? fc.onLime : fc.muted,
              filled: false,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: active
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        label,
                        maxLines: 1,
                        style: FT.body(
                          14,
                          weight: FontWeight.w700,
                          color: fc.onLime,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
