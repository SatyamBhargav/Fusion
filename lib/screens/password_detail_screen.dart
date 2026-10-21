import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/password_generator.dart';
import '../services/vault_item.dart';
import '../services/vault_store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/components.dart';
import '../widgets/feedback.dart';
import '../widgets/icons.dart';
import '../widgets/motion.dart';
import 'login_form_screen.dart';

class PasswordDetailScreen extends StatefulWidget {
  const PasswordDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<PasswordDetailScreen> createState() => _PasswordDetailScreenState();
}

class _PasswordDetailScreenState extends State<PasswordDetailScreen> {
  bool _reveal = false;
  VaultItem? _last;

  static const _toastBottom = 96.0;

  Future<void> _openSite(String site) async {
    var s = site.trim();
    if (!s.startsWith(RegExp(r'https?://', caseSensitive: false))) {
      s = 'https://$s';
    }
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      final uri = Uri.tryParse(s);
      if (uri != null) {
        ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      showFusionToastOn(
        messenger,
        'Couldn’t open that website',
        icon: FIcons.info,
        bottom: _toastBottom,
      );
    }
  }

  Future<void> _delete(VaultItem item) async {
    final store = context.read<VaultStore>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showConfirmSheet(
      context,
      title: 'Delete ${item.name}?',
      message:
          'This login will be removed from your vault on this device. You can’t undo this.',
      confirmLabel: 'Delete login',
    );
    if (!ok) return;
    nav.pop();
    await store.delete(item.id);
    showFusionToastOn(
      messenger,
      '${item.name} deleted',
      icon: FIcons.trash,
      bottom: 108,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<VaultStore>();
    // Keep showing the last known item while the page animates away after a delete.
    final item = store.byId(widget.itemId) ?? _last;
    if (item == null) return const Scaffold(backgroundColor: FC.bg);
    _last = item;

    final provider = providerById(item.provider);
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightStatusBar,
      child: Scaffold(
        backgroundColor: FC.bg,
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _Header(
                      item: item,
                      topInset: topInset,
                      onStar: () => store.toggleFavourite(item.id),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -36),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            FadeSlideIn(
                              offset: 28,
                              delay: const Duration(milliseconds: 80),
                              child: _infoCard(item, provider),
                            ),
                            const SizedBox(height: 16),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 160),
                              child: _statsRow(item, provider),
                            ),
                            if (item.note.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 220),
                                child: _NoteCard(note: item.note),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 260),
                  child: Row(
                    children: [
                      SquareIconButton(
                        icon: FIcons.trash,
                        label: 'Delete login',
                        bg: FC.dangerTint,
                        fg: FC.danger,
                        bordered: false,
                        size: 56,
                        radius: 18,
                        iconSize: 22,
                        stroke: 2,
                        onTap: () => _delete(item),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Edit login',
                          color: FC.ink,
                          glow: false,
                          leadingIcon: FIcons.pencil,
                          onTap: () => Navigator.of(
                            context,
                          ).push(fusionRoute(LoginFormScreen(existing: item))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(VaultItem item, SocialProvider provider) {
    final rows = <Widget>[
      _InfoRow(
        label: item.isSocial ? 'ACCOUNT' : 'USERNAME',
        value: Text(
          item.username.isEmpty ? '—' : item.username,
          style: FT.body(16, weight: FontWeight.w500),
        ),
        actions: [
          if (item.username.isNotEmpty)
            _RoundAction(
              icon: FIcons.copy,
              label: 'Copy username',
              onTap: () => copyToClipboard(
                context,
                item.username,
                'Username',
                bottom: _toastBottom,
              ),
            ),
        ],
      ),
      if (!item.isSocial)
        _InfoRow(
          label: 'PASSWORD',
          value: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(a),
                child: c,
              ),
            ),
            child: Text(
              _reveal
                  ? item.password
                  : '•' * item.password.length.clamp(8, 14).toInt(),
              key: ValueKey(_reveal),
              style: FT.mono(
                _reveal ? 17 : 18,
                spacing: _reveal ? 0.5 : 3,
                weight: FontWeight.w500,
              ),
            ),
          ),
          actions: [
            _RoundAction(
              icon: _reveal ? FIcons.eyeOff : FIcons.eye,
              label: _reveal ? 'Hide password' : 'Show password',
              onTap: () => setState(() => _reveal = !_reveal),
            ),
            _RoundAction(
              icon: FIcons.copy,
              label: 'Copy password',
              primary: true,
              onTap: () => copyToClipboard(
                context,
                item.password,
                'Password',
                secret: true,
                bottom: _toastBottom,
              ),
            ),
          ],
        )
      else
        _InfoRow(
          label: 'SIGNS IN WITH',
          value: Row(
            children: [
              MonogramTile(
                text: provider.name,
                letter: provider.mono,
                size: 28,
                radius: 9,
                fontSize: 13,
                bg: provider.tile,
                fg: provider.ink,
              ),
              const SizedBox(width: 10),
              Text(provider.name, style: FT.body(16, weight: FontWeight.w600)),
            ],
          ),
          actions: const [],
        ),
      if (item.website.isNotEmpty)
        _InfoRow(
          label: 'WEBSITE',
          value: Text(
            item.website,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FT.body(16, weight: FontWeight.w500),
          ),
          actions: [
            _RoundAction(
              icon: FIcons.external,
              label: 'Open website',
              onTap: () => _openSite(item.website),
            ),
          ],
        ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1416142B),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? const Border(bottom: BorderSide(color: FC.divider))
                    : null,
              ),
              child: rows[i],
            ),
        ],
      ),
    );
  }

  Widget _statsRow(VaultItem item, SocialProvider provider) {
    final s = strengthOf(item.password);
    final left = item.isSocial
        ? _StatCard(
            tinted: true,
            label: 'SIGN-IN',
            child: Text(
              'Continue with ${provider.name}',
              style: FT.display(17, weight: FontWeight.w700, spacing: -0.3),
            ),
          )
        : _StatCard(
            tinted: true,
            label: 'STRENGTH',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(4, (i) {
                    return Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: i < s.score ? 1 : 0),
                        duration: Duration(milliseconds: 400 + i * 120),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => Container(
                          height: 6,
                          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              const Color(0x333D4A0B),
                              FC.limeInk,
                              v,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  s.label.isEmpty ? '—' : s.label,
                  style: FT.display(17, weight: FontWeight.w700, spacing: -0.3),
                ),
              ],
            ),
          );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'LAST EDITED',
              child: Text(
                relativeTime(item.updatedAt),
                style: FT.display(17, weight: FontWeight.w700, spacing: -0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.item,
    required this.topInset,
    required this.onStar,
  });

  final VaultItem item;
  final double topInset;
  final VoidCallback onStar;

  @override
  Widget build(BuildContext context) {
    final sub = item.host.isNotEmpty
        ? item.host
        : (item.isSocial ? item.subtitle : 'Saved login');
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: Container(
        color: FC.violet,
        child: Stack(
          children: [
            const Positioned(
              right: -70,
              bottom: -110,
              child: PopIn(
                delay: Duration(milliseconds: 120),
                child: Blob(size: 200, color: FC.lime),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SquareIconButton(
                        icon: FIcons.back,
                        label: 'Back to vault',
                        bg: FC.onVioletGlass,
                        fg: Colors.white,
                        bordered: false,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      StarButton(
                        active: item.favourite,
                        onTap: onStar,
                        label: item.favourite
                            ? 'Remove from favourites'
                            : 'Add to favourites',
                        bg: FC.onVioletGlass,
                        activeBg: FC.lime,
                        activeColor: FC.ink,
                        inactiveColor: Colors.white,
                        radius: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      MonogramTile(
                        text: item.name,
                        size: 68,
                        radius: 22,
                        fontSize: 30,
                        bg: Colors.white,
                        fg: FC.violetDeep,
                        heroTag: 'tile-${item.id}',
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FadeSlideIn(
                          offset: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: FT.display(
                                  32,
                                  color: Colors.white,
                                  spacing: -1,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FT.body(14, color: FC.onViolet),
                              ),
                            ],
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
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.actions,
  });

  final String label;
  final Widget value;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: FT.eyebrow()),
                  const SizedBox(height: 4),
                  value,
                ],
              ),
            ),
          ),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            actions[i],
          ],
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SquareIconButton(
      icon: icon,
      label: label,
      onTap: onTap,
      bg: primary ? FC.violet : FC.bg,
      fg: primary ? Colors.white : FC.ink,
      bordered: false,
      iconSize: 18,
      stroke: 2,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.child,
    this.tinted = false,
  });

  final String label;
  final Widget child;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tinted ? FC.limeTint : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: tinted ? null : Border.all(color: FC.line, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: FT.eyebrow(color: tinted ? FC.limeInk : FC.muted)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FC.line, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOTE', style: FT.eyebrow()),
          const SizedBox(height: 6),
          SelectableText(
            note,
            style: FT.body(15, color: FC.ink2, height: 1.45),
          ),
        ],
      ),
    );
  }
}
