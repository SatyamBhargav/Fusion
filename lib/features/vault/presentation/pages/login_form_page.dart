import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/bloc/effects.dart';
import '../../../../core/router/draft_password.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/icons.dart';
import '../../../../core/widgets/motion.dart';
import '../../domain/entities/vault_item.dart';
import '../bloc/vault_bloc.dart';
import '../cubits/login_form_cubit.dart';
import '../social_providers.dart';

/// Add or edit a login — either a stored password or a social sign-in.
///
/// With [itemId] it edits that login. A new one starts with the password
/// the generator left in [DraftPassword], if any.
class LoginFormPage extends StatelessWidget {
  const LoginFormPage({super.key, this.itemId});

  final String? itemId;

  @override
  Widget build(BuildContext context) {
    final id = itemId;
    return BlocProvider(
      create: (context) => sl<LoginFormCubit>(
        param1: id == null ? null : context.read<VaultBloc>().state.byId(id),
        param2: id == null ? sl<DraftPassword>().take() : null,
      ),
      child: const _LoginFormView(),
    );
  }
}

class _LoginFormView extends StatefulWidget {
  const _LoginFormView();

  @override
  State<_LoginFormView> createState() => _LoginFormViewState();
}

class _LoginFormViewState extends State<_LoginFormView> {
  late final TextEditingController _name;
  late final TextEditingController _site;
  late final TextEditingController _user;
  late final TextEditingController _pass;
  late final TextEditingController _account;
  late final TextEditingController _note;
  final _shake = GlobalKey<ShakeState>();

  late final LoginFormCubit _cubit = context.read<LoginFormCubit>();

  bool get _isEdit => _cubit.isEdit;

  @override
  void initState() {
    super.initState();
    final e = _cubit.existing;
    final social = e?.kind == LoginKind.social;
    _name = TextEditingController(text: e?.name ?? '');
    _site = TextEditingController(text: e?.website ?? '');
    _user = TextEditingController(text: social ? '' : (e?.username ?? ''));
    _pass = TextEditingController(text: _cubit.state.password);
    _account = TextEditingController(text: social ? e!.username : '');
    _note = TextEditingController(text: e?.note ?? '');
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
    final pw = await context.push<String>(Routes.pickPassword);
    if (pw != null && mounted) {
      _pass.text = pw;
      _cubit.passwordPicked(pw);
    }
  }

  void _save() {
    FocusScope.of(context).unfocus();
    _cubit.save(
      LoginFormFields(
        name: _name.text,
        website: _site.text,
        username: _user.text,
        password: _pass.text,
        account: _account.text,
        note: _note.text,
      ),
    );
  }

  void _onEffect(BuildContext context, LoginFormEffect effect) {
    final messenger = ScaffoldMessenger.of(context);
    switch (effect) {
      case LoginFormInvalid():
        HapticFeedback.heavyImpact();
        _shake.currentState?.shake();
      case LoginFormSaveFailed(:final message):
        showFusionToastOn(messenger, message, icon: FIcons.info);
      case LoginFormSaved(:final name):
        HapticFeedback.mediumImpact();
        context.pop();
        showFusionToastOn(
          messenger,
          _isEdit ? 'Changes saved' : '$name saved to vault',
          bottom: _isEdit ? 96 : 108,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final form = context.watch<LoginFormCubit>().state;
    final provider = providerById(form.provider);
    final isPassword = form.kind == LoginKind.password;

    return EffectListener<LoginFormCubit, LoginFormEffect>(
      listener: _onEffect,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: statusBarFor(context),
        child: Scaffold(
          backgroundColor: fc.bg,
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
                              onChanged: (i) => _cubit.kindChanged(
                                i == 0 ? LoginKind.password : LoginKind.social,
                              ),
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
                                    error: form.nameError,
                                    onChanged: (_) => _cubit.nameChanged(),
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
                                    ? _passwordSection(form)
                                    : _socialSection(form, provider),
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
                              label: _isEdit
                                  ? 'Favourite'
                                  : 'Add to favourites',
                              value: form.favourite,
                              onChanged: _cubit.favouriteChanged,
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
                    loading: form.saving,
                    onTap: _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordSection(LoginFormState form) {
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
          obscure: form.obscure,
          mono: !form.obscure,
          error: form.passwordError,
          onChanged: _cubit.passwordChanged,
          trailing: [
            EyeButton(obscured: form.obscure, onTap: _cubit.toggleObscure),
            const SizedBox(width: 2),
            GenerateChip(onTap: _generate),
          ],
        ),
        const SizedBox(height: 10),
        StrengthMeter(password: form.password),
      ],
    );
  }

  Widget _socialSection(LoginFormState form, SocialProvider provider) {
    final fc = context.fc;
    Widget tile(SocialProvider p) => Expanded(
      child: _ProviderTile(
        provider: p,
        selected: p.id == form.provider,
        onTap: () {
          HapticFeedback.selectionClick();
          _cubit.providerChanged(p.id);
        },
      ),
    );

    return Column(
      key: const ValueKey('social'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('I sign in with', style: FT.label(color: fc.ink2)),
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
            color: fc.limeTint,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: FIcon(FIcons.shieldCheck, color: fc.limeInk),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No password to remember. Fusion keeps note of which account you use, so you always tap the right button.',
                  style: FT.body(14, color: fc.limeText, height: 1.45),
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
    final fc = context.fc;
    return Pressable(
      onTap: onTap,
      semanticLabel: provider.name,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        height: 84,
        decoration: BoxDecoration(
          color: selected ? fc.violetTint : fc.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? fc.violet : fc.line, width: 2),
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
                  decoration: BoxDecoration(
                    color: fc.violet,
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
