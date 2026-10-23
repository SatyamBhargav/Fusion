import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/icons.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../core/widgets/nav_clearance.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/vault_item.dart';
import '../../domain/entities/vault_snapshot.dart';
import '../bloc/vault_bloc.dart';
import '../cubits/vault_filter_cubit.dart';
import '../social_providers.dart';

/// The vault list, or with [favouritesOnly] the Starred tab.
class VaultPage extends StatelessWidget {
  const VaultPage({
    super.key,
    this.favouritesOnly = false,
    this.onSeeFavourites,
  });

  final bool favouritesOnly;

  /// "See all" next to the favourites row; filters in place when null.
  final VoidCallback? onSeeFavourites;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<VaultFilterCubit>(param1: favouritesOnly),
    child: _VaultView(
      favouritesOnly: favouritesOnly,
      onSeeFavourites: onSeeFavourites,
    ),
  );
}

class _VaultView extends StatefulWidget {
  const _VaultView({required this.favouritesOnly, this.onSeeFavourites});

  final bool favouritesOnly;
  final VoidCallback? onSeeFavourites;

  @override
  State<_VaultView> createState() => _VaultViewState();
}

class _VaultViewState extends State<_VaultView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(VaultItem item) => context.push(Routes.item(item.id));

  void _star(VaultItem item) =>
      context.read<VaultBloc>().add(VaultFavouriteToggled(item.id));

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final filterCubit = context.read<VaultFilterCubit>();
    final view = context.watch<VaultFilterCubit>().state;
    final store = context.watch<VaultBloc>().state;
    final first = context.watch<AuthBloc>().state.firstName;
    final filter = view.effectiveFilter;
    final query = view.query;
    final list = view.apply(store.items);

    final favs = store.favourites;
    final showFavRow =
        !widget.favouritesOnly &&
        filter == VaultFilter.all &&
        query.isEmpty &&
        favs.isNotEmpty;

    final sectionTitle = widget.favouritesOnly
        ? 'Starred logins'
        : switch (filter) {
            VaultFilter.all => 'All passwords',
            VaultFilter.favourites => 'Favourites',
            VaultFilter.passwords => 'Passwords',
            VaultFilter.social => 'Social sign-ins',
          };

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, navClearance(context)),
        children: [
          FadeSlideIn(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        first.isEmpty ? 'Hi there' : 'Hi, $first',
                        style: FT.body(14, color: fc.muted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.favouritesOnly ? 'Favourites' : 'Your vault',
                        style: FT.display(32, spacing: -1),
                      ),
                    ],
                  ),
                ),
                PopIn(
                  delay: const Duration(milliseconds: 120),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: fc.lime,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      first.isEmpty ? 'F' : first.substring(0, 1).toUpperCase(),
                      style: FT.display(
                        20,
                        color: fc.onLime,
                        spacing: 0,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: FusionField(
              label: 'Search passwords',
              showLabel: false,
              controller: _search,
              icon: FIcons.search,
              hint: 'Search passwords',
              height: 52,
              action: TextInputAction.search,
              onChanged: filterCubit.search,
              trailing: [
                AnimatedScale(
                  scale: query.isEmpty ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: SquareIconButton(
                    icon: FIcons.close,
                    label: 'Clear search',
                    bg: Colors.transparent,
                    bordered: false,
                    fg: fc.muted,
                    iconSize: 16,
                    onTap: () {
                      _search.clear();
                      filterCubit.clearSearch();
                    },
                  ),
                ),
              ],
            ),
          ),
          if (!widget.favouritesOnly) ...[
            const SizedBox(height: 18),
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: view.filter == VaultFilter.all,
                      onTap: () => filterCubit.select(VaultFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Favourites',
                      star: true,
                      selected: view.filter == VaultFilter.favourites,
                      onTap: () => filterCubit.select(VaultFilter.favourites),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Passwords',
                      selected: view.filter == VaultFilter.passwords,
                      onTap: () => filterCubit.select(VaultFilter.passwords),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Social',
                      selected: view.filter == VaultFilter.social,
                      onTap: () => filterCubit.select(VaultFilter.social),
                    ),
                  ],
                ),
              ),
            ),
          ],
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: showFavRow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Favourites',
                              style: FT.display(
                                19,
                                weight: FontWeight.w700,
                                spacing: -0.3,
                              ),
                            ),
                          ),
                          TextLink(
                            'See all',
                            onTap:
                                widget.onSeeFavourites ??
                                () =>
                                    filterCubit.select(VaultFilter.favourites),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 128,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: favs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) => FadeSlideIn(
                            key: ValueKey('fav-${favs[i].id}'),
                            delay: Duration(
                              milliseconds: 120 + 60 * math.min(i, 5),
                            ),
                            offset: 12,
                            child: _FavCard(
                              item: favs[i],
                              variant: i % 3,
                              onTap: () => _open(favs[i]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                sectionTitle,
                style: FT.display(19, weight: FontWeight.w700, spacing: -0.3),
              ),
              const SizedBox(width: 8),
              if (store.loaded) CountPill(list.length),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
            child: !store.loaded
                ? const Padding(
                    key: ValueKey('loading'),
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : list.isEmpty
                ? KeyedSubtree(
                    key: ValueKey('empty-$filter-$query'),
                    child: _empty(store, filter, query),
                  )
                : _ListCard(
                    key: const ValueKey('list'),
                    items: list,
                    onOpen: _open,
                    onStar: _star,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _empty(VaultSnapshot store, VaultFilter filter, String query) {
    if (store.readFailed) {
      return const EmptyState(
        icon: FIcons.info,
        title: 'Couldn’t open your vault',
        message:
            'Your saved logins couldn’t be read from this device. Lock the vault from Settings and try again.',
      );
    }
    if (store.items.isEmpty) {
      return const EmptyState(
        title: 'Your vault is empty',
        message:
            'Tap the + button to save your first login, or make a strong one in the generator.',
      );
    }
    if (query.isNotEmpty) {
      return EmptyState(
        icon: FIcons.search,
        title: 'No matches',
        message: 'Nothing in your vault matches “$query”.',
      );
    }
    if (filter == VaultFilter.favourites) {
      return const EmptyState(
        icon: FIcons.star,
        title: 'No favourites yet',
        message: 'Tap the star on any login to pin it here.',
      );
    }
    return const EmptyState(
      title: 'Nothing here yet',
      message: 'Logins you save in this category will show up here.',
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.star = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool star;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: star ? 14 : 18),
        decoration: BoxDecoration(
          color: selected ? fc.panel : fc.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? fc.panel : fc.line, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (star) ...[
              FIcon(
                FIcons.star,
                size: 16,
                filled: true,
                color: selected ? fc.lime : fc.violet,
              ),
              const SizedBox(width: 6),
            ],
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: FT.body(
                14,
                weight: FontWeight.w700,
                color: selected ? Colors.white : fc.ink,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavCard extends StatelessWidget {
  const _FavCard({
    required this.item,
    required this.variant,
    required this.onTap,
  });

  final VaultItem item;
  final int variant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    final Color bg;
    final Color fg;
    final Color sub;
    final Color tileBg;
    final Color tileFg;
    final Color star;
    switch (variant) {
      case 0:
        bg = fc.violet;
        fg = Colors.white;
        sub = fc.onViolet;
        tileBg = fc.onVioletGlass;
        tileFg = Colors.white;
        star = fc.lime;
      case 1:
        bg = fc.lime;
        fg = fc.onLime;
        // Lime is the same in both themes, so its content stays fixed too.
        sub = FC.light.ink2;
        tileBg = fc.onLime;
        tileFg = fc.lime;
        star = fc.onLime;
      default:
        final p = paletteFor(item.name);
        bg = fc.surface;
        fg = fc.ink;
        sub = fc.muted;
        tileBg = p.$1;
        tileFg = p.$2;
        star = fc.violet;
    }
    return Pressable(
      onTap: onTap,
      semanticLabel: '${item.name}, ${item.subtitle}, favourite',
      child: Container(
        width: 152,
        height: 128,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: variant == 2 ? Border.all(color: fc.line, width: 1.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MonogramTile(
                  text: item.name,
                  size: 40,
                  radius: 13,
                  bg: tileBg,
                  fg: tileFg,
                ),
                FIcon(FIcons.star, size: 18, filled: true, color: star),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FT.body(16, weight: FontWeight.w700, color: fg),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FT.body(12, color: sub),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    super.key,
    required this.items,
    required this.onOpen,
    required this.onStar,
  });

  final List<VaultItem> items;
  final ValueChanged<VaultItem> onOpen;
  final ValueChanged<VaultItem> onStar;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        decoration: BoxDecoration(
          color: fc.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: fc.line, width: 1.5),
        ),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++)
              FadeSlideIn(
                key: ValueKey(items[i].id),
                delay: Duration(milliseconds: 160 + 45 * math.min(i, 8)),
                offset: 14,
                child: _Row(
                  item: items[i],
                  divider: i < items.length - 1,
                  onOpen: () => onOpen(items[i]),
                  onStar: () => onStar(items[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.item,
    required this.divider,
    required this.onOpen,
    required this.onStar,
  });

  final VaultItem item;
  final bool divider;
  final VoidCallback onOpen;
  final VoidCallback onStar;

  @override
  Widget build(BuildContext context) {
    final fc = context.fc;
    return Container(
      height: 68,
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: fc.divider)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: onOpen,
              scale: 0.98,
              semanticLabel: '${item.name}, ${item.subtitle}',
              child: Row(
                children: [
                  MonogramTile(text: item.name, heroTag: 'tile-${item.id}'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FT.body(15, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        if (item.isSocial)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: fc.violetTint,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              item.subtitle,
                              style: FT.body(
                                12,
                                weight: FontWeight.w700,
                                color: fc.violetDeep,
                              ),
                            ),
                          )
                        else
                          Text(
                            item.username.isEmpty ? item.host : item.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FT.body(13, color: fc.muted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          StarButton(
            active: item.favourite,
            onTap: onStar,
            label: item.favourite
                ? 'Remove ${item.name} from favourites'
                : 'Add ${item.name} to favourites',
          ),
        ],
      ),
    );
  }
}
