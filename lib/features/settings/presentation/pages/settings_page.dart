import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/bloc/effects.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/icons.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../core/widgets/nav_clearance.dart';
import '../../../app_lock/domain/entities/biometric_kind.dart';
import '../../../app_lock/presentation/biometric_label.dart';
import '../../../app_lock/presentation/bloc/app_lock_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../vault/presentation/bloc/vault_bloc.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/theme_cubit.dart';

/// Order of the appearance toggle's segments.
const _themeModes = [
  AppThemeMode.light,
  AppThemeMode.dark,
  AppThemeMode.system,
];

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<SettingsCubit>(),
    child: const EffectListener<SettingsCubit, SettingsEffect>(
      listener: _onEffect,
      child: _SettingsView(),
    ),
  );

  static void _onEffect(BuildContext context, SettingsEffect effect) {
    switch (effect) {
      case BiometricNotVerified(:final label):
        showFusionToast(context, 'Couldn’t verify $label', icon: FIcons.info);
    }
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final settings = context.read<SettingsCubit>();
    final account = context.watch<AuthBloc>().state.account;
    final count = context.watch<VaultBloc>().state.items.length;
    final theme = context.watch<ThemeCubit>().state;
    final lock = context.watch<AppLockBloc>().state.status;
    final hasBiometric = lock.kind != BiometricKind.none;
    final bioLabel = lock.kind.label;
    final name = (account?.name ?? '').trim();
    final initial = name.isEmpty ? 'F' : name.substring(0, 1).toUpperCase();

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
                                  account?.email ?? '',
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
                    index: _themeModes.indexOf(theme),
                    labels: const ['Light', 'Dark', 'System'],
                    icons: const [FIcons.sun, FIcons.moon, FIcons.contrast],
                    onChanged: (i) =>
                        context.read<ThemeCubit>().select(_themeModes[i]),
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
                  if (hasBiometric) ...[
                    _SwitchRow(
                      icon: lock.kind == BiometricKind.face
                          ? FIcons.faceId
                          : FIcons.fingerprint,
                      title: 'Unlock with $bioLabel',
                      subtitle: 'Skip typing your PIN',
                      value: lock.biometricEnabled,
                      onChanged: (on) => settings.setBiometric(on, bioLabel),
                    ),
                    Divider(height: 1, color: fc.divider),
                  ],
                  _SettingsRow(
                    icon: FIcons.key,
                    title: 'Change PIN',
                    subtitle: 'Pick a new 6-digit PIN',
                    onTap: () => context.push(Routes.changePin),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 300),
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
                    subtitle: lock.canUseBiometric
                        ? 'Ask for your PIN or $bioLabel'
                        : 'Ask for your PIN',
                    onTap: settings.lockVault,
                  ),
                  Divider(height: 1, color: fc.divider),
                  _SettingsRow(
                    icon: FIcons.trash,
                    title: 'Erase this vault',
                    subtitle: 'Delete your account and every saved login',
                    danger: true,
                    onTap: () async {
                      final ok = await showConfirmSheet(
                        context,
                        title: 'Erase everything?',
                        message:
                            'Your account and all saved logins will be permanently deleted from this device.',
                        confirmLabel: 'Erase vault',
                      );
                      if (ok) await settings.eraseEverything();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const FadeSlideIn(
            delay: Duration(milliseconds: 360),
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

/// A settings row ending in a switch; tapping anywhere on it toggles.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fc.violetTint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: FIcon(icon, size: 19, color: fc.violet),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: FT.body(15, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: FT.body(13, color: fc.muted)),
                ],
              ),
            ),
            FusionSwitch(value: value, onChanged: onChanged, label: title),
          ],
        ),
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
