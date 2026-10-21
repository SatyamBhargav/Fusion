import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/vault_store.dart';
import '../theme.dart';
import '../widgets/components.dart';
import '../widgets/feedback.dart';
import '../widgets/icons.dart';
import '../widgets/motion.dart';
import 'home_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final store = context.watch<VaultStore>();
    final name = (auth.name ?? '').trim();
    final initial = name.isEmpty ? 'F' : name.substring(0, 1).toUpperCase();
    final count = store.items.length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, navClearance(context)),
        children: [
          FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your account', style: FT.body(14, color: FC.muted)),
                const SizedBox(height: 2),
                Text('Settings', style: FT.display(32, spacing: -1)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            offset: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                color: FC.violet,
                child: Stack(
                  children: [
                    const Positioned(
                      right: -40,
                      bottom: -60,
                      child: PopIn(
                        delay: Duration(milliseconds: 200),
                        child: Blob(size: 130, color: FC.lime),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: FC.lime,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              initial,
                              style: FT.display(24, spacing: 0, height: 1),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isEmpty ? 'Fusion user' : name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FT.display(
                                    20,
                                    color: Colors.white,
                                    spacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  auth.email ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FT.body(14, color: FC.onViolet),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: FC.ink,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              count == 1 ? '1 login' : '$count logins',
                              style: FT.body(
                                12,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FC.limeTint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FIcon(FIcons.shieldCheck, color: FC.limeInk),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stored only on this device',
                          style: FT.body(
                            15,
                            weight: FontWeight.w700,
                            color: FC.limeText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your vault lives in your phone’s secure storage. Nothing is uploaded anywhere.',
                          style: FT.body(14, color: FC.limeText, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: FC.line, width: 1.5),
              ),
              child: Column(
                children: [
                  _SettingsRow(
                    icon: FIcons.lock,
                    title: 'Lock vault',
                    subtitle: 'Ask for your master password again',
                    onTap: () {
                      context.read<VaultStore>().reset();
                      context.read<AuthService>().logout();
                    },
                  ),
                  const Divider(height: 1, color: FC.divider),
                  _SettingsRow(
                    icon: FIcons.trash,
                    title: 'Erase this vault',
                    subtitle: 'Delete your account and every saved login',
                    danger: true,
                    onTap: () async {
                      final vault = context.read<VaultStore>();
                      final authService = context.read<AuthService>();
                      final ok = await showConfirmSheet(
                        context,
                        title: 'Erase everything?',
                        message:
                            'Your account and all saved logins will be permanently deleted from this device.',
                        confirmLabel: 'Erase vault',
                      );
                      if (!ok) return;
                      await vault.clear();
                      vault.reset();
                      await authService.wipe();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      semanticLabel: '$title. $subtitle',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: danger ? FC.dangerTint : FC.violetTint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: FIcon(
                icon,
                size: 19,
                color: danger ? FC.danger : FC.violet,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FT.body(
                      15,
                      weight: FontWeight.w700,
                      color: danger ? FC.danger : FC.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: FT.body(13, color: FC.muted)),
                ],
              ),
            ),
            const FIcon(FIcons.chevronRight, size: 18, color: FC.muted),
          ],
        ),
      ),
    );
  }
}
