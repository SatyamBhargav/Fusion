import '../../../../core/usecase/usecase.dart';
import '../entities/vault_snapshot.dart';
import '../repositories/vault_repository.dart';

class GetVault implements UseCase<VaultSnapshot, NoParams> {
  const GetVault(this._vault);

  final VaultRepository _vault;

  @override
  VaultSnapshot call([NoParams _ = const NoParams()]) => _vault.current;
}
