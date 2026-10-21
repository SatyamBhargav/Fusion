import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/vault_item.dart';
import '../services/vault_store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/components.dart';
import '../widgets/feedback.dart';
import '../widgets/icons.dart';
import '../widgets/motion.dart';
import 'generator_screen.dart';

/// Add or edit a login — either a stored password or a social sign-in.
class LoginFormScreen extends StatefulWidget {
  const LoginFormScreen({super.key, this.existing, this.initialPassword});

  final VaultItem? existing;
  final String? initialPassword;

  @override
  State<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _site;
  late final TextEditingController _user;
  late final TextEditingController _pass;
  late final TextEditingController _account;
  late final TextEditingController _note;
  final _shake = GlobalKey<ShakeState>();

  late LoginKind _kind;
  late String _provider;
  late bool _fav;
  bool _obscure = true;
  bool _saving = false;
  String? _nameErr;
  String? _passErr;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final social = e?.kind == LoginKind.social;
    _name = TextEditingController(text: e?.name ?? '');
    _site = TextEditingController(text: e?.website ?? '');
    _user = TextEditingController(text: social ? '' : (e?.username ?? ''));
    _pass = TextEditingController(
      text: e?.password ?? widget.initialPassword ?? '',
    );
    _account = TextEditingController(text: social ? e!.username : '');
    _note = TextEditingController(text: e?.note ?? '');
    _kind = e?.kind ?? LoginKind.password;
    _provider = e?.provider ?? 'google';
    _fav = e?.favourite ?? false;
    if (widget.initialPassword != null) _obscure = false;
  }

  @override
  void dispose() {
    _name.dispose();
    _site.dispose();
    _user.dispose();
    _pass.dispose();
    _account.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final pw = await Navigator.of(
      context,
    ).push<String>(fusionRoute(const GeneratorScreen(pickMode: true)));
    if (pw != null && mounted) {
      setState(() {
        _pass.text = pw;
        _obscure = false;
        _passErr = null;
      });
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _nameErr = _name.text.trim().isEmpty ? 'Give this login a name' : null;
      _passErr = _kind == LoginKind.password && _pass.text.isEmpty
          ? 'Enter or generate a password'
          : null;
    });
    if (_nameErr != null || _passErr != null) {
      HapticFeedback.heavyImpact();
      _shake.currentState?.shake();
      return;
    }

    final store = context.read<VaultStore>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final isPassword = _kind == LoginKind.password;
    final item = VaultItem(
      id: widget.existing?.id ?? newId(),
      name: _name.text.trim(),
      website: _site.text.trim(),
      username: isPassword ? _user.text.trim() : _account.text.trim(),
      password: isPassword ? _pass.text : '',
      note: _note.text.trim(),
      favourite: _fav,
      kind: _kind,
      provider: _provider,
      updatedAt: DateTime.now(),
    );

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await store.update(item);
      } else {
        await store.add(item);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showFusionToastOn(
        messenger,
        'Couldn’t save. Please try again.',
        icon: FIcons.info,
      );
      return;
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    nav.pop();
    showFusionToastOn(
      messenger,
      _isEdit ? 'Changes saved' : '${item.name} saved to vault',
      bottom: _isEdit ? 96 : 108,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = providerById(_provider);
    final isPassword = _kind == LoginKind.password;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: darkStatusBar,
      child: Scaffold(
        backgroundColor: FC.bg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    BackButtonF(
                      icon: _isEdit ? FIcons.close : FIcons.back,
                      label: _isEdit ? 'Cancel editing' : 'Back',
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _isEdit ? 'Edit login' : 'Save a login',
                        style: FT.display(26, spacing: -0.8),
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _name,
                      builder: (_, v, __) => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder: (c, a) => ScaleTransition(
                          scale: CurvedAnimation(
                            parent: a,
                            curve: Curves.easeOutBack,
                          ),
                          child: c,
                        ),
                        child: MonogramTile(
                          key: ValueKey(
                            '${monogramOf(v.text)}-${paletteFor(v.text).hashCode}',
                          ),
                          text: v.text.isEmpty ? '?' : v.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Shake(
                    key: _shake,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeSlideIn(
                          child: SegmentedToggle(
                            index: isPassword ? 0 : 1,
                            labels: const ['Password', 'Social sign-in'],
                            icons: const [FIcons.key, FIcons.users],
                            onChanged: (i) => setState(() {
                              _kind = i == 0
                                  ? LoginKind.password
                                  : LoginKind.social;
                              _passErr = null;
                            }),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 60),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: FusionField(
                                  label: 'Name',
                                  controller: _name,
                                  hint: 'e.g. Spotify',
                                  height: 52,
                                  capitalization: TextCapitalization.words,
                                  action: TextInputAction.next,
                                  error: _nameErr,
                                  onChanged: (_) {
                                    if (_nameErr != null) {
                                      setState(() => _nameErr = null);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FusionField(
                                  label: 'Website',
                                  controller: _site,
                                  hint: 'spotify.com',
                                  height: 52,
                                  keyboardType: TextInputType.url,
                                  action: TextInputAction.next,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 120),
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 360),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              layoutBuilder: (current, previous) => Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  ...previous,
                                  if (current != null) current,
                                ],
                              ),
                              transitionBuilder: (c, a) => FadeTransition(
                                opacity: a,
                                child: SlideTransition(
                                  position: Tween(
                                    begin: Offset(
                                      c.key == const ValueKey('pw')
                                          ? -0.06
                                          : 0.06,
                                      0,
                                    ),
                                    end: Offset.zero,
                                  ).animate(a),
                                  child: c,
                                ),
                              ),
                              child: isPassword
                                  ? _passwordSection()
                                  : _socialSection(provider),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 180),
                          child: FusionField(
                            label: 'Note',
                            controller: _note,
                            hint: 'Anything worth remembering',
                            maxLines: 3,
                            capitalization: TextCapitalization.sentences,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 220),
                          child: FavouriteToggleRow(
                            label: _isEdit ? 'Favourite' : 'Add to favourites',
                            value: _fav,
                            onChanged: (v) => setState(() => _fav = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: PrimaryButton(
                  label: _isEdit ? 'Save changes' : 'Save to vault',
                  loading: _saving,
                  onTap: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordSection() {
    return Column(
      key: const ValueKey('pw'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FusionField(
          label: 'Username or email',
          controller: _user,
          hint: 'you@example.com',
          height: 52,
          keyboardType: TextInputType.emailAddress,
          action: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
        ),
        const SizedBox(height: 16),
        FusionField(
          label: 'Password',
          controller: _pass,
          hint: 'Type or generate',
          obscure: _obscure,
          mono: !_obscure,
          error: _passErr,
          onChanged: (_) => setState(() => _passErr = null),
          trailing: [
            EyeButton(
              obscured: _obscure,
              onTap: () => setState(() => _obscure = !_obscure),
            ),
            const SizedBox(width: 2),
            GenerateChip(onTap: _generate),
          ],
        ),
        const SizedBox(height: 10),
        StrengthMeter(password: _pass.text),
      ],
    );
  }

  Widget _socialSection(SocialProvider provider) {
    Widget tile(SocialProvider p) => Expanded(
      child: _ProviderTile(
        provider: p,
        selected: p.id == _provider,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _provider = p.id);
        },
      ),
    );

    return Column(
      key: const ValueKey('social'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('I sign in with', style: FT.label()),
        const SizedBox(height: 10),
        Row(
          children: [
            tile(socialProviders[0]),
            const SizedBox(width: 10),
            tile(socialProviders[1]),
            const SizedBox(width: 10),
            tile(socialProviders[2]),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            tile(socialProviders[3]),
            const SizedBox(width: 10),
            tile(socialProviders[4]),
            const SizedBox(width: 10),
            tile(socialProviders[5]),
          ],
        ),
        const SizedBox(height: 16),
        FusionField(
          label: '${provider.name} account',
          controller: _account,
          hint: 'you@example.com',
          height: 52,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: FC.limeTint,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: FIcon(FIcons.shieldCheck, color: FC.limeInk),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No password to remember. Fusion keeps note of which account you use, so you always tap the right button.',
                  style: FT.body(14, color: FC.limeText, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.provider,
    required this.selected,
    required this.onTap,
  });

  final SocialProvider provider;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: provider.name,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        height: 84,
        decoration: BoxDecoration(
          color: selected ? FC.violetTint : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? FC.violet : FC.line, width: 2),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.08 : 1,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    child: MonogramTile(
                      text: provider.name,
                      letter: provider.mono,
                      size: 36,
                      radius: 12,
                      fontSize: 16,
                      bg: provider.tile,
                      fg: provider.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.name,
                    style: FT.body(13, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: AnimatedScale(
                scale: selected ? 1 : 0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: FC.violet,
                    shape: BoxShape.circle,
                  ),
                  child: const FIcon(
                    FIcons.check,
                    size: 12,
                    color: Colors.white,
                    stroke: 3.2,
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
