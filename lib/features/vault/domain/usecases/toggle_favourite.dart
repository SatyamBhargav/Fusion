import '../../../../core/usecase/usecase.dart';
import '../repositories/vault_repository.dart';

class ToggleFavourite implements UseCase<Future<void>, String> {
  const ToggleFavourite(this._vault);

  final VaultRepository _vault;

  @override
  Future<void> call(String id) => _vault.toggleFavourite(id);
}
