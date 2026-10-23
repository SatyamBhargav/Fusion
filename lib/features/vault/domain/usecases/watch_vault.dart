import '../../../../core/usecase/usecase.dart';
import '../entities/vault_snapshot.dart';
import '../repositories/vault_repository.dart';

/// Every change to the vault, from now on.
class WatchVault implements UseCase<Stream<VaultSnapshot>, NoParams> {
  const WatchVault(this._vault);

  final VaultRepository _vault;

  @override
  Stream<VaultSnapshot> call([NoParams _ = const NoParams()]) => _vault.changes;
}
