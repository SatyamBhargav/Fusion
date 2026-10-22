import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'hashing.dart';
import 'storage.dart';

typedef AuthError = ({String field, String message});
typedef ResetRequest = ({String? code, String? error});

/// Local-only account: one master password per device, stored as a salted,
/// stretched SHA-256 hash in secure storage. Nothing leaves the device.
class AuthService extends ChangeNotifier {
  AuthService({FlutterSecureStorage? storage})
    : _storage = storage ?? fusionStorage;

  static const _key = 'fusion.account.v1';
  final FlutterSecureStorage _storage;

  bool _ready = false;
  bool _loggedIn = false;
  bool _passwordVerified = false;
  String? _name;
  String? _email;
  String? _salt;
  String? _hash;
  String? _resetCode;
  DateTime? _resetExpiry;

  bool get ready => _ready;
  bool get loggedIn => _loggedIn;

  /// True when this session was opened with the master password (not the
  /// app lock), e.g. so a forgotten PIN can be replaced without the old one.
  bool get passwordVerified => _loggedIn && _passwordVerified;
  bool get hasAccount => _hash != null;
  String? get name => _name;
  String? get email => _email;
  String get firstName {
    final n = (_name ?? '').trim();
    if (n.isEmpty) return '';
    return n.split(RegExp(r'\s+')).first;
  }

  Future<void> init() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        _name = m['name'] as String?;
        _email = m['email'] as String?;
        _salt = m['salt'] as String?;
        _hash = m['hash'] as String?;
      }
    } catch (_) {
      // Corrupt or unreadable storage: treat as a fresh device.
    }
    _ready = true;
    notifyListeners();
  }

  static String _norm(String email) => email.trim().toLowerCase();

  Future<void> _save({
    required String? name,
    required String? email,
    required String salt,
    required String hash,
  }) => _storage.write(
    key: _key,
    value: jsonEncode({
      'name': name,
      'email': email,
      'salt': salt,
      'hash': hash,
    }),
  );

  Future<AuthError?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (hasAccount) {
      return (
        field: 'email',
        message: 'This device already has a Fusion vault. Log in instead.',
      );
    }
    final salt = newSalt();
    final hash = await hashInBackground(salt, password);
    final cleanName = name.trim();
    final cleanEmail = _norm(email);
    // Persist first; only update in-memory state once the write succeeded.
    await _save(name: cleanName, email: cleanEmail, salt: salt, hash: hash);
    _name = cleanName;
    _email = cleanEmail;
    _salt = salt;
    _hash = hash;
    _loggedIn = true;
    _passwordVerified = true;
    notifyListeners();
    return null;
  }

  Future<AuthError?> login(String email, String password) async {
    if (!hasAccount) {
      return (
        field: 'email',
        message: 'No vault on this device yet. Create an account first.',
      );
    }
    if (_norm(email) != _email) {
      return (field: 'email', message: 'That email doesn’t match this vault.');
    }
    final hash = await hashInBackground(_salt!, password);
    if (!constantTimeEquals(hash, _hash!)) {
      return (field: 'password', message: 'Wrong master password. Try again.');
    }
    _loggedIn = true;
    _passwordVerified = true;
    notifyListeners();
    return null;
  }

  /// Creates a 6-digit reset code valid for 10 minutes. With no server the
  /// code is delivered as an on-device notification banner.
  ResetRequest requestReset(String email) {
    if (!hasAccount) {
      return (code: null, error: 'There’s no vault on this device yet.');
    }
    if (_norm(email) != _email) {
      return (code: null, error: 'That email doesn’t match this vault.');
    }
    final r = math.Random.secure();
    final code = List.generate(6, (_) => r.nextInt(10)).join();
    _resetCode = code;
    _resetExpiry = DateTime.now().add(const Duration(minutes: 10));
    return (code: code, error: null);
  }

  Future<AuthError?> resetPassword(String code, String newPassword) async {
    final expiry = _resetExpiry;
    final expected = _resetCode;
    if (expected == null || expiry == null || DateTime.now().isAfter(expiry)) {
      return (field: 'code', message: 'That code has expired. Send a new one.');
    }
    if (!constantTimeEquals(code, expected)) {
      return (
        field: 'code',
        message: 'That code isn’t right. Check and try again.',
      );
    }
    final salt = newSalt();
    final hash = await hashInBackground(salt, newPassword);
    await _save(name: _name, email: _email, salt: salt, hash: hash);
    _hash = hash;
    _salt = salt;
    _resetCode = null;
    _resetExpiry = null;
    notifyListeners();
    return null;
  }

  /// Opens the vault after the app lock (PIN or biometrics) let the user in.
  void unlockWithAppLock() {
    if (!hasAccount || _loggedIn) return;
    _loggedIn = true;
    _passwordVerified = false;
    notifyListeners();
  }

  void logout() {
    _loggedIn = false;
    _passwordVerified = false;
    notifyListeners();
  }

  /// Erases the account and every stored login on this device.
  Future<void> wipe() async {
    await _storage.deleteAll();
    _name = null;
    _email = null;
    _salt = null;
    _hash = null;
    _loggedIn = false;
    _passwordVerified = false;
    notifyListeners();
  }
}
