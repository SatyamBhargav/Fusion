import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('unlockWithAppLock', () {
    test('opens the vault for an existing account', () async {
      final auth = AuthService();
      await auth.init();
      await auth.signUp(name: 'Ada', email: 'ada@x.io', password: 'pw');
      auth.logout();

      auth.unlockWithAppLock();
      expect(auth.loggedIn, isTrue);
    });

    test('does nothing without an account', () async {
      final auth = AuthService();
      await auth.init();
      auth.unlockWithAppLock();
      expect(auth.loggedIn, isFalse);
    });
  });

  group('passwordVerified', () {
    test('is set by a master password login or signup', () async {
      final auth = AuthService();
      await auth.init();
      await auth.signUp(name: 'Ada', email: 'ada@x.io', password: 'pw');
      expect(auth.passwordVerified, isTrue);
      auth.logout();
      expect(auth.passwordVerified, isFalse);
      await auth.login('ada@x.io', 'pw');
      expect(auth.passwordVerified, isTrue);
    });

    test('is not set by the app lock', () async {
      final auth = AuthService();
      await auth.init();
      await auth.signUp(name: 'Ada', email: 'ada@x.io', password: 'pw');
      auth.logout();
      auth.unlockWithAppLock();
      expect(auth.loggedIn, isTrue);
      expect(auth.passwordVerified, isFalse);
    });
  });

  test('existing master passwords still log in after the hash move', () async {
    final auth = AuthService();
    await auth.init();
    await auth.signUp(name: 'Ada', email: 'ada@x.io', password: 'pw');
    auth.logout();
    expect(await auth.login('ada@x.io', 'nope'), isNotNull);
    expect(await auth.login('ada@x.io', 'pw'), isNull);
    expect(auth.loggedIn, isTrue);
  });
}
