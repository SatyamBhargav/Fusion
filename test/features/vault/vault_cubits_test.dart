import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/app/di/injection.dart';
import 'package:fusion/features/vault/domain/entities/vault_item.dart';
import 'package:fusion/features/vault/domain/repositories/vault_repository.dart';
import 'package:fusion/features/vault/presentation/bloc/vault_bloc.dart';
import 'package:fusion/features/vault/presentation/cubits/login_form_cubit.dart';
import 'package:fusion/features/vault/presentation/cubits/password_detail_cubit.dart';
import 'package:fusion/features/vault/presentation/cubits/vault_filter_cubit.dart';

import '../../helpers/di.dart';
import '../../helpers/seeds.dart';

const _fields = LoginFormFields(
  name: ' Spotify ',
  website: 'spotify.com',
  username: 'ada',
  password: 'pw-1',
  account: 'ada@x.io',
  note: '',
);

VaultItem _item(
  String id,
  String name, {
  bool fav = false,
  bool social = false,
}) => VaultItem(
  id: id,
  name: name,
  website: '$name.com'.toLowerCase(),
  username: 'ada',
  password: 'pw',
  note: '',
  favourite: fav,
  kind: social ? LoginKind.social : LoginKind.password,
  provider: 'google',
  updatedAt: DateTime(2026),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultBloc', () {
    test('loads on request and toggles favourites', () async {
      await setUpDi(
        loggedIn: true,
        items: [vaultItemJson(id: 'a', name: 'GitHub')],
      );
      final bloc = sl<VaultBloc>();
      expect(bloc.state.loaded, isFalse);
      bloc.add(const VaultLoadRequested());
      await flush();
      await flush();
      expect(bloc.state.items.single.name, 'GitHub');
      bloc.add(const VaultFavouriteToggled('a'));
      await flush();
      await flush();
      expect(bloc.state.favourites, hasLength(1));
    });
  });

  group('VaultFilterState', () {
    final items = [
      _item('1', 'GitHub', fav: true),
      _item('2', 'Google', social: true),
      _item('3', 'Netflix'),
    ];

    test('filters by kind and favourite', () {
      const s = VaultFilterState(favouritesOnly: false);
      expect(s.apply(items), hasLength(3));
      expect(
        s.copyWith(filter: VaultFilter.social).apply(items).single.id,
        '2',
      );
      expect(
        s.copyWith(filter: VaultFilter.passwords).apply(items).map((e) => e.id),
        ['1', '3'],
      );
      expect(
        const VaultFilterState(favouritesOnly: true).apply(items).single.id,
        '1',
      );
    });

    test('search matches name, username or website', () {
      final cubit = VaultFilterCubit(favouritesOnly: false)..search('  NETF ');
      expect(cubit.state.query, 'netf');
      expect(cubit.state.apply(items).single.id, '3');
      cubit.clearSearch();
      expect(cubit.state.apply(items), hasLength(3));
    });
  });

  group('LoginFormCubit', () {
    setUp(() => setUpDi(loggedIn: true));

    test('needs a name and, for passwords, a password', () async {
      final cubit = sl<LoginFormCubit>();
      final effects = <LoginFormEffect>[];
      cubit.effects.listen(effects.add);
      await cubit.save(
        const LoginFormFields(
          name: ' ',
          website: '',
          username: '',
          password: '',
          account: '',
          note: '',
        ),
      );
      await flush();
      expect(cubit.state.nameError, 'Give this login a name');
      expect(cubit.state.passwordError, 'Enter or generate a password');
      expect(effects.single, isA<LoginFormInvalid>());
    });

    test('saves a new login', () async {
      await sl<VaultRepository>().load();
      final cubit = sl<LoginFormCubit>();
      final effects = <LoginFormEffect>[];
      cubit.effects.listen(effects.add);
      await cubit.save(_fields);
      await flush();
      expect((effects.single as LoginFormSaved).name, 'Spotify');
      final saved = sl<VaultRepository>().current.items.single;
      expect(saved.name, 'Spotify');
      expect(saved.password, 'pw-1');
    });

    test('a social sign-in keeps the account and no password', () async {
      await sl<VaultRepository>().load();
      final cubit = sl<LoginFormCubit>()
        ..kindChanged(LoginKind.social)
        ..providerChanged('apple');
      await cubit.save(_fields);
      final saved = sl<VaultRepository>().current.items.single;
      expect(saved.username, 'ada@x.io');
      expect(saved.password, '');
      expect(saved.provider, 'apple');
    });

    test('editing keeps the id', () async {
      await sl<VaultRepository>().load();
      await sl<VaultRepository>().add(_item('x', 'Old'));
      final existing = sl<VaultRepository>().current.byId('x');
      final cubit = sl<LoginFormCubit>(param1: existing);
      expect(cubit.isEdit, isTrue);
      await cubit.save(_fields);
      expect(sl<VaultRepository>().current.items.single.id, 'x');
      expect(sl<VaultRepository>().current.items.single.name, 'Spotify');
    });

    test('a generated password starts visible', () {
      final cubit = sl<LoginFormCubit>(param2: 'Gen3rated!');
      expect(cubit.state.password, 'Gen3rated!');
      expect(cubit.state.obscure, isFalse);
    });
  });

  group('PasswordDetailCubit', () {
    test('follows the item and keeps it after a delete', () async {
      await setUpDi(
        loggedIn: true,
        items: [vaultItemJson(id: 'a', name: 'GitHub')],
      );
      await sl<VaultRepository>().load();
      final cubit = sl<PasswordDetailCubit>(param1: 'a');
      expect(cubit.state.item?.name, 'GitHub');
      await cubit.toggleFavourite();
      await flush();
      expect(cubit.state.item?.favourite, isTrue);
      await cubit.delete();
      await flush();
      expect(sl<VaultRepository>().current.items, isEmpty);
      expect(cubit.state.item?.name, 'GitHub');
      cubit.toggleReveal();
      expect(cubit.state.reveal, isTrue);
      await cubit.close();
    });
  });
}
