import 'dart:async';
import 'dart:math' as math;

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/security/hashing.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/account_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._local, {
    required PasswordHasher hasher,
    DateTime Function()? clock,
  }) : _hasher = hasher,
       _now = clock ?? DateTime.now;

  final AuthLocalDataSource _local;
  final PasswordHasher _hasher;
  final DateTime Function() _now;
  final _changes = StreamController<AuthSession>.broadcast();

  AccountModel? _stored;
  AuthSession _session = const AuthSession();
  String? _resetCode;
  DateTime? _resetExpiry;
  String? _resetEmail;

  @override
  AuthSession get current => _session;

  @override
  Stream<AuthSession> get changes => _changes.stream;

  @override
  String? get pendingResetEmail => _resetEmail;

  void _set(AuthSession next) {
    if (next == _session) return;
    _session = next;
    _changes.add(next);
  }

  void _store(AccountModel? stored) {
    // An account only counts once it has a password hash.
    _stored = stored?.hash == null ? null : stored;
    _set(_session.copyWith(account: () => _stored?.toEntity()));
  }

  static String _norm(String email) => email.trim().toLowerCase();

  @override
  Future<void> init() async {
    AccountModel? stored;
    try {
      stored = await _local.read();
    } catch (_) {
      // Corrupt or unreadable storage: treat as a fresh device.
    }
    _stored = stored?.hash == null ? null : stored;
    _set(_session.copyWith(ready: true, account: () => _stored?.toEntity()));
  }

  @override
  Future<Result<void>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_session.hasAccount) {
      return const Err(
        AuthFailure(
          AuthField.email,
          'This device already has a Fusion vault. Log in instead.',
        ),
      );
    }
    try {
      final salt = newSalt();
      final hash = await _hasher(salt, password);
      final model = AccountModel(
        name: name.trim(),
        email: _norm(email),
        salt: salt,
        hash: hash,
      );
      // Persist first; only update in-memory state once the write succeeded.
      await _local.write(model);
      _stored = model;
      _set(
        _session.copyWith(
          loggedIn: true,
          passwordVerified: true,
          account: model.toEntity,
        ),
      );
      return ok;
    } catch (_) {
      return const Err(
        AuthFailure(AuthField.email, 'Couldn’t create your vault. Try again.'),
      );
    }
  }

  @override
  Future<Result<void>> logIn(String email, String password) async {
    final stored = _stored;
    if (stored == null) {
      return const Err(
        AuthFailure(
          AuthField.email,
          'No vault on this device yet. Create an account first.',
        ),
      );
    }
    if (_norm(email) != stored.email) {
      return const Err(
        AuthFailure(AuthField.email, 'That email doesn’t match this vault.'),
      );
    }
    try {
      final hash = await _hasher(stored.salt!, password);
      if (!constantTimeEquals(hash, stored.hash!)) {
        return const Err(
          AuthFailure(AuthField.password, 'Wrong master password. Try again.'),
        );
      }
    } catch (_) {
      return const Err(
        AuthFailure(AuthField.password, 'Something went wrong. Try again.'),
      );
    }
    _set(_session.copyWith(loggedIn: true, passwordVerified: true));
    return ok;
  }

  @override
  Result<String> requestReset(String email) {
    final stored = _stored;
    if (stored == null) {
      return const Err(
        AuthFailure(AuthField.email, 'There’s no vault on this device yet.'),
      );
    }
    if (_norm(email) != stored.email) {
      return const Err(
        AuthFailure(AuthField.email, 'That email doesn’t match this vault.'),
      );
    }
    final r = math.Random.secure();
    final code = List.generate(6, (_) => r.nextInt(10)).join();
    _resetCode = code;
    _resetExpiry = _now().add(const Duration(minutes: 10));
    _resetEmail = email.trim();
    return Ok(code);
  }

  @override
  Future<Result<void>> resetPassword(String code, String newPassword) async {
    final expiry = _resetExpiry;
    final expected = _resetCode;
    if (expected == null || expiry == null || _now().isAfter(expiry)) {
      return const Err(
        AuthFailure(AuthField.code, 'That code has expired. Send a new one.'),
      );
    }
    if (!constantTimeEquals(code, expected)) {
      return const Err(
        AuthFailure(
          AuthField.code,
          'That code isn’t right. Check and try again.',
        ),
      );
    }
    try {
      final salt = newSalt();
      final hash = await _hasher(salt, newPassword);
      final model = AccountModel(
        name: _stored?.name,
        email: _stored?.email,
        salt: salt,
        hash: hash,
      );
      await _local.write(model);
      _resetCode = null;
      _resetExpiry = null;
      _store(model);
      return ok;
    } catch (_) {
      return const Err(
        AuthFailure(
          AuthField.code,
          'Couldn’t save the new password. Try again.',
        ),
      );
    }
  }

  @override
  void unlock() {
    if (!_session.hasAccount || _session.loggedIn) return;
    _set(_session.copyWith(loggedIn: true, passwordVerified: false));
  }

  @override
  void logOut() {
    _set(_session.copyWith(loggedIn: false, passwordVerified: false));
  }

  @override
  Future<void> wipe() async {
    await _local.deleteAll();
    _stored = null;
    _resetCode = null;
    _resetExpiry = null;
    _resetEmail = null;
    _set(
      _session.copyWith(
        loggedIn: false,
        passwordVerified: false,
        account: () => null,
      ),
    );
  }
}
