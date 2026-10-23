import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vault_item.dart';

enum VaultFilter { all, favourites, passwords, social }

class VaultFilterState extends Equatable {
  const VaultFilterState({
    required this.favouritesOnly,
    this.filter = VaultFilter.all,
    this.query = '',
  });

  /// The Starred tab: always favourites, no filter chips.
  final bool favouritesOnly;
  final VaultFilter filter;

  /// Trimmed and lower-cased.
  final String query;

  VaultFilter get effectiveFilter =>
      favouritesOnly ? VaultFilter.favourites : filter;

  List<VaultItem> apply(List<VaultItem> items) {
    var list = switch (effectiveFilter) {
      VaultFilter.favourites => items.where((e) => e.favourite),
      VaultFilter.passwords => items.where((e) => !e.isSocial),
      VaultFilter.social => items.where((e) => e.isSocial),
      VaultFilter.all => items,
    };
    if (query.isNotEmpty) {
      list = list.where(
        (e) =>
            e.name.toLowerCase().contains(query) ||
            e.username.toLowerCase().contains(query) ||
            e.website.toLowerCase().contains(query),
      );
    }
    return list.toList();
  }

  VaultFilterState copyWith({VaultFilter? filter, String? query}) =>
      VaultFilterState(
        favouritesOnly: favouritesOnly,
        filter: filter ?? this.filter,
        query: query ?? this.query,
      );

  @override
  List<Object?> get props => [favouritesOnly, filter, query];
}

/// Filter chips and search on a vault list.
class VaultFilterCubit extends Cubit<VaultFilterState> {
  VaultFilterCubit({required bool favouritesOnly})
    : super(VaultFilterState(favouritesOnly: favouritesOnly));

  void select(VaultFilter filter) => emit(state.copyWith(filter: filter));

  void search(String text) =>
      emit(state.copyWith(query: text.trim().toLowerCase()));

  void clearSearch() => emit(state.copyWith(query: ''));
}
