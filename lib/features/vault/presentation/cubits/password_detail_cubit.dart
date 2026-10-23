import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vault_item.dart';
import '../../domain/entities/vault_snapshot.dart';
import '../../domain/usecases/delete_vault_item.dart';
import '../../domain/usecases/get_vault.dart';
import '../../domain/usecases/toggle_favourite.dart';
import '../../domain/usecases/watch_vault.dart';

class PasswordDetailState extends Equatable {
  const PasswordDetailState({this.item, this.reveal = false});

  /// The latest version of the item. Kept after a delete so the page can
  /// still draw while it animates away.
  final VaultItem? item;
  final bool reveal;

  @override
  List<Object?> get props => [item, reveal];
}

class PasswordDetailCubit extends Cubit<PasswordDetailState> {
  PasswordDetailCubit({
    required String itemId,
    required GetVault getVault,
    required WatchVault watchVault,
    required ToggleFavourite toggleFavourite,
    required DeleteVaultItem deleteVaultItem,
  }) : _id = itemId,
       _toggleFavourite = toggleFavourite,
       _delete = deleteVaultItem,
       super(PasswordDetailState(item: getVault().byId(itemId))) {
    _sub = watchVault().listen(_onVault);
  }

  final String _id;
  final ToggleFavourite _toggleFavourite;
  final DeleteVaultItem _delete;
  late final StreamSubscription<VaultSnapshot> _sub;

  void _onVault(VaultSnapshot v) => emit(
    PasswordDetailState(item: v.byId(_id) ?? state.item, reveal: state.reveal),
  );

  void toggleReveal() =>
      emit(PasswordDetailState(item: state.item, reveal: !state.reveal));

  Future<void> toggleFavourite() => _toggleFavourite(_id);

  /// Deletes the item. Can be awaited after the page has closed.
  Future<void> delete() => _delete(_id);

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
