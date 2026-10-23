import '../../../../core/usecase/usecase.dart';
import '../repositories/vault_repository.dart';

class DeleteVaultItem implements UseCase<Future<void>, String> {
  const DeleteVaultItem(this._vault);

  final VaultRepository _vault;

  @override
  Future<void> call(String id) => _vault.delete(id);
}
