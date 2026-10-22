import '../../../../core/usecase/usecase.dart';
import '../repositories/vault_repository.dart';

/// Reads the stored vault into memory.
class LoadVault implements UseCase<Future<void>, NoParams> {
  const LoadVault(this._vault);

  final VaultRepository _vault;

  @override
  Future<void> call([NoParams _ = const NoParams()]) => _vault.load();
}
