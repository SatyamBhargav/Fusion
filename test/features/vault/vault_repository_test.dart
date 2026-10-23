import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/core/error/result.dart';
import 'package:fusion/core/storage/secure_storage.dart';
import 'package:fusion/features/vault/data/datasources/vault_local_data_source.dart';
import 'package:fusion/features/vault/data/models/vault_item_model.dart';
import 'package:fusion/features/vault/data/repositories/vault_repository_impl.dart';
import 'package:fusion/features/vault/domain/entities/vault_item.dart';
import 'package:fusion/features/vault/domain/usecases/save_vault_item.dart';

VaultItem _item(String id, String name, {bool favourite = false}) => VaultItem(
  id: id,
  name: name,
  website: '',
  username: 'ada',
  password: 'pw',
  note: '',
  favourite: favourite,
  kind: LoginKind.password,
  provider: 'google',
  updatedAt: DateTime(2026, 1, 1),
);

class _FailingWrites implements VaultLocalDataSource {
  @override
  Future<List<VaultItem>> read() async => [_item('1', 'Kept')];

  @override
  Future<void> write(List<VaultItem> items) async => throw StateError('full');

  @override
  Future<void> delete() async {}
}

Future<VaultRepositoryImpl> _vault() async {
  final v = VaultRepositoryImpl(
    const SecureVaultLocalDataSource(fusionStorage),
  );
  await v.load();
  return v;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('loads sorted by name and saves across instances', () async {
    final v = await _vault();
    await v.add(_item('1', 'zeta'));
    await v.add(_item('2', 'Alpha'));
    expect(v.current.items.map((e) => e.name), ['Alpha', 'zeta']);

    final fresh = await _vault();
    expect(fresh.current.items.map((e) => e.id), ['2', '1']);
  });

  test('update replaces by id; favourites toggle', () async {
    final v = await _vault();
    await v.add(_item('1', 'GitHub'));
    await v.update(_item('1', 'GitHub (work)'));
    await v.toggleFavourite('1');
    expect(v.current.items.single.name, 'GitHub (work)');
    expect(v.current.favourites.single.id, '1');
    expect(v.current.byId('1')?.favourite, isTrue);
  });

  test('delete removes the item', () async {
    final v = await _vault();
    await v.add(_item('1', 'GitHub'));
    await v.delete('1');
    expect((await _vault()).current.items, isEmpty);
  });

  test('refuses to overwrite storage it could not read', () async {
    FlutterSecureStorage.setMockInitialValues({StorageKeys.vault: 'not json'});
    final v = await _vault();
    expect(v.current.loaded, isTrue);
    expect(v.current.readFailed, isTrue);
    await expectLater(v.add(_item('1', 'GitHub')), throwsStateError);
    expect(v.current.items, isEmpty);
    expect(await fusionStorage.read(key: StorageKeys.vault), 'not json');
  });

  test('a failed save rolls back; deletes fail quietly', () async {
    final v = VaultRepositoryImpl(_FailingWrites());
    await v.load();
    await expectLater(v.add(_item('2', 'New')), throwsStateError);
    expect(v.current.items.map((e) => e.id), ['1']);
    await v.delete('1');
    expect(v.current.items.map((e) => e.id), ['1']);
  });

  test('SaveVaultItem turns a failed save into a failure', () async {
    final v = VaultRepositoryImpl(_FailingWrites());
    await v.load();
    final r = await SaveVaultItem(v)(
      SaveVaultItemParams(_item('2', 'New'), isNew: true),
    );
    expect(r, isA<Err<void>>());
  });

  test('forget drops the decrypted vault until loaded again', () async {
    final v = await _vault();
    await v.add(_item('1', 'GitHub'));
    v.forget();
    expect(v.current.loaded, isFalse);
    expect(v.current.items, isEmpty);
    await v.load();
    expect(v.current.items, hasLength(1));
  });

  test('clear deletes the stored vault', () async {
    final v = await _vault();
    await v.add(_item('1', 'GitHub'));
    await v.clear();
    expect(await fusionStorage.read(key: StorageKeys.vault), isNull);
  });

  test('the stored JSON format is unchanged', () {
    final item = VaultItem(
      id: '1',
      name: 'Dribbble',
      website: 'dribbble.com',
      username: 'aanya@example.com',
      password: '',
      note: 'n',
      favourite: true,
      kind: LoginKind.social,
      provider: 'apple',
      updatedAt: DateTime(2026, 1, 1),
    );
    final json = VaultItemModel.toJson(item);
    expect(
      jsonEncode(json),
      '{"id":"1","name":"Dribbble","website":"dribbble.com",'
      '"username":"aanya@example.com","password":"","note":"n",'
      '"favourite":true,"kind":"social","provider":"apple",'
      '"updatedAt":"2026-01-01T00:00:00.000"}',
    );
    expect(VaultItemModel.fromJson(json), item);
  });

  test('old records with missing fields still load', () {
    final item = VaultItemModel.fromJson({'id': '9', 'name': 'Old'});
    expect(item.kind, LoginKind.password);
    expect(item.provider, 'google');
    expect(item.favourite, isFalse);
  });
}
