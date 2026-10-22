import '../../../../core/error/result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/vault_item.dart';
import '../repositories/vault_repository.dart';

class SaveVaultItemParams {
  const SaveVaultItemParams(this.item, {required this.isNew});

  final VaultItem item;
  final bool isNew;
}

/// Adds a new login or saves changes to an existing one.
class SaveVaultItem
    implements UseCase<Future<Result<void>>, SaveVaultItemParams> {
  const SaveVaultItem(this._vault);

  final VaultRepository _vault;

  @override
  Future<Result<void>> call(SaveVaultItemParams p) async {
    try {
      if (p.isNew) {
        await _vault.add(p.item);
      } else {
        await _vault.update(p.item);
      }
      return ok;
    } catch (_) {
      return const Err(StorageFailure('Couldn’t save. Please try again.'));
    }
  }
}
