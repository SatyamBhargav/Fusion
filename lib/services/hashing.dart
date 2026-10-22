import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Salted SHA-256 stretched over 20k rounds. Used for the master password and
/// the app-lock PIN.
String stretchHash(String salt, String secret) {
  final bytes = utf8.encode('$salt::$secret');
  var digest = sha256.convert(bytes).bytes;
  for (var i = 0; i < 20000; i++) {
    digest = sha256.convert([...digest, ...bytes]).bytes;
  }
  return base64Encode(digest);
}

String _hashWorker(List<String> args) => stretchHash(args[0], args[1]);

/// Runs [stretchHash] on a background isolate so the UI keeps animating.
Future<String> hashInBackground(String salt, String secret) =>
    compute(_hashWorker, [salt, secret]);

String newSalt() {
  final r = math.Random.secure();
  return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
}

bool constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}
