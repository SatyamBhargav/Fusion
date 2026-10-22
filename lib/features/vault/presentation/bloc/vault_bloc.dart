import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vault_snapshot.dart';
import '../../domain/usecases/get_vault.dart';
import '../../domain/usecases/load_vault.dart';
import '../../domain/usecases/toggle_favourite.dart';
import '../../domain/usecases/watch_vault.dart';

sealed class VaultEvent {
  const VaultEvent();
}

/// Reads the stored vault if it isn't in memory yet.
final class VaultLoadRequested extends VaultEvent {
  const VaultLoadRequested();
}

final class VaultFavouriteToggled extends VaultEvent {
  const VaultFavouriteToggled(this.id);

  final String id;
}

final class _VaultChanged extends VaultEvent {
  const _VaultChanged(this.snapshot);

  final VaultSnapshot snapshot;
}

/// The decrypted vault, for every screen that lists or counts logins.
class VaultBloc extends Bloc<VaultEvent, VaultSnapshot> {
  VaultBloc({
    required GetVault getVault,
    required WatchVault watchVault,
    required LoadVault loadVault,
    required ToggleFavourite toggleFavourite,
  }) : super(getVault()) {
    on<_VaultChanged>((e, emit) => emit(e.snapshot));
    on<VaultLoadRequested>((e, emit) => loadVault());
    on<VaultFavouriteToggled>((e, emit) => toggleFavourite(e.id));
    _sub = watchVault().listen((s) => add(_VaultChanged(s)));
  }

  late final StreamSubscription<VaultSnapshot> _sub;

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
