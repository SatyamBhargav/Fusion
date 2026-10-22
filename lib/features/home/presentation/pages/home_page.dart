import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/icons.dart';
import '../../../../core/widgets/motion.dart';
import '../../../generator/presentation/pages/generator_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../vault/presentation/bloc/vault_bloc.dart';
import '../../../vault/presentation/pages/vault_page.dart';
import '../cubit/home_tab_cubit.dart';

/// The open vault: four tabs under a floating nav bar.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _tabs = sl<HomeTabCubit>();

  @override
  void initState() {
    super.initState();
    context.read<VaultBloc>().add(const VaultLoadRequested());
  }

  @override
  void dispose() {
    _tabs.close();
    super.dispose();
  }

  void _go(HomeTab tab) {
    if (_tabs.select(tab)) HapticFeedback.selectionClick();
  }

  Widget _page(HomeTab tab) {
    return switch (tab) {
      HomeTab.vault => VaultPage(onSeeFavourites: () => _go(HomeTab.starred)),
      HomeTab.generator => const GeneratorPage(),
      HomeTab.starred => const VaultPage(favouritesOnly: true),
      HomeTab.settings => const SettingsPage(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return BlocProvider.value(
      value: _tabs,
      child: BlocBuilder<HomeTabCubit, HomeTab>(
        builder: (context, tab) => AnnotatedRegion<SystemUiOverlayStyle>(
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
                          HeroMode(
                            key: current.key,
                            enabled: true,
                            child: current,
                          ),
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
                    child: KeyedSubtree(key: ValueKey(tab), child: _page(tab)),
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
                        tab: tab,
                        onTab: _go,
                        onAdd: () => context.push(Routes.newItem),
                      ),
                    ),
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

class _NavBar extends StatelessWidget {
  const _NavBar({required this.tab, required this.onTab, required this.onAdd});

  final HomeTab tab;
  final ValueChanged<HomeTab> onTab;
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
            active: tab == HomeTab.vault,
            onTap: () => onTab(HomeTab.vault),
          ),
          _NavItem(
            icon: FIcons.sparkle,
            label: 'Generate',
            active: tab == HomeTab.generator,
            onTap: () => onTab(HomeTab.generator),
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
            active: tab == HomeTab.starred,
            onTap: () => onTab(HomeTab.starred),
          ),
          _NavItem(
            icon: FIcons.sliders,
            label: 'Settings',
            active: tab == HomeTab.settings,
            onTap: () => onTab(HomeTab.settings),
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
