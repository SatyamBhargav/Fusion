import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/theme_controller.dart';
import '../services/vault_store.dart';
import '../theme.dart';
import '../widgets/components.dart';
import '../widgets/feedback.dart';
import '../widgets/icons.dart';
import '../widgets/motion.dart';
import 'home_shell.dart';

/// Order of the appearance toggle's segments.
const _themeModes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final auth = context.watch<AuthService>();
    final store = context.watch<VaultStore>();
    final theme = context.watch<ThemeController>();
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
                Text('Your account', style: FT.body(14, color: fc.muted)),
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
                color: fc.violet,
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      bottom: -60,
                      child: PopIn(
                        delay: const Duration(milliseconds: 200),
                        child: Blob(size: 130, color: fc.lime),
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
                            decoration: BoxDecoration(
                              color: fc.lime,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              initial,
                              style: FT.display(
                                24,
                                color: fc.onLime,
                                spacing: 0,
                                height: 1,
                              ),
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
                                  style: FT.body(14, color: fc.onViolet),
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
                              color: fc.panel,
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
                color: fc.limeTint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FIcon(FIcons.shieldCheck, color: fc.limeInk),
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
                            color: fc.limeText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your vault lives in your phone’s secure storage. Nothing is uploaded anywhere.',
                          style: FT.body(14, color: fc.limeText, height: 1.45),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: fc.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: fc.line, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: fc.violetTint,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: FIcon(
                          FIcons.contrast,
                          size: 19,
                          color: fc.violet,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appearance',
                              style: FT.body(15, weight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Match your device or pick a look',
                              style: FT.body(13, color: fc.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SegmentedToggle(
                    index: _themeModes.indexOf(theme.mode),
                    labels: const ['Light', 'Dark', 'System'],
                    icons: const [FIcons.sun, FIcons.moon, FIcons.contrast],
                    onChanged: (i) =>
                        context.read<ThemeController>().setMode(_themeModes[i]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 240),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: fc.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: fc.line, width: 1.5),
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
                  Divider(height: 1, color: fc.divider),
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
          const SizedBox(height: 28),
          const FadeSlideIn(
            delay: Duration(milliseconds: 300),
            child: _VersionLabel(),
          ),
        ],
      ),
    );
  }
}

/// "Fusion v1.0.0 (1)", read from the platform build at runtime.
class _VersionLabel extends StatefulWidget {
  const _VersionLabel();

  @override
  State<_VersionLabel> createState() => _VersionLabelState();
}

class _VersionLabelState extends State<_VersionLabel> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (context, snap) {
        final info = snap.data;
        if (info == null) return const SizedBox(height: 18);
        final build = info.buildNumber.isEmpty ? '' : ' (${info.buildNumber})';
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FusionLogo(size: 18),
            const SizedBox(width: 8),
            Text(
              'Fusion v${info.version}$build',
              style: FT.body(13, color: context.fc.muted),
            ),
          ],
        );
      },
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
    final fc = context.fc;
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
                color: danger ? fc.dangerTint : fc.violetTint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: FIcon(
                icon,
                size: 19,
                color: danger ? fc.danger : fc.violet,
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
                      color: danger ? fc.danger : fc.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: FT.body(13, color: fc.muted)),
                ],
              ),
            ),
            FIcon(FIcons.chevronRight, size: 18, color: fc.muted),
          ],
        ),
      ),
    );
  }
}
