
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart' as path;

Future<Database> _openDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  final db = await sql.openDatabase(
    path.join(dbPath, 'userProfile.db'),
    onCreate: (db, version) {
      return db.execute('CREATE TABLE user_Profile(name TEXT)');
    },
    version: 1,
  );
  return db;
}

class UserAvatarNotifier extends StateNotifier<String> {
  UserAvatarNotifier() : super('assets/images/default.png');

  Future<void> loaddetails() async {
    final db = await _openDatabase();
    final data = await db.query('user_Profile');
    if (data.isNotEmpty) {
      final details = data.first['name'] as String;
      state = details;
    }
  }

  void getUserAvatar(String imagePath) async {
    state = imagePath;
    final db = await _openDatabase();
    db.insert('user_Profile', {'name': imagePath},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

final userprofileprovider =
    StateNotifierProvider<UserAvatarNotifier, String>((ref) {
  return UserAvatarNotifier();
});

























// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:sqflite/sqflite.dart' as sql;
// import 'package:sqflite/sqlite_api.dart';
// import 'package:path/path.dart' as path;

// Future<Database> _openDatabase() async {
//   final dbPath = await sql.getDatabasesPath();
//   final db = await sql.openDatabase(
//     path.join(dbPath, 'userProfile.db'),
//     onCreate: (db, version) {
//       return db.execute('CREATE TABLE user_Profile(name TEXT)');
//     },
//     version: 1,
//   );
//   return db;
// }

// class UserAvatarNotifier extends StateNotifier<Image> {
//   UserAvatarNotifier()
//       : super(Image.asset('assets/images/default.png', height: 60));

//   Future<void> loaddetails() async {
//     final db = await _openDatabase();
//     final data = await db.query('user_Profile');
//     final details = data.map(
//       (row) => row['name'] as Image,
//     ) as Image;
//     state = details;
//   }

//   void getUserAvatar(Image userAvatar) async {
//     state = userAvatar;
//     final db = await _openDatabase();
//     db.insert('user_Profile', {'name': userAvatar as String});
//   }
// }

// final userprofileprovider =
//     StateNotifierProvider<UserAvatarNotifier, Image>((ref) {
//   return UserAvatarNotifier();
// });
