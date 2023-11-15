import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart' as path;

Future<Database> _openDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  final db = await sql.openDatabase(
    path.join(dbPath, 'userName.db'),
    onCreate: (db, version) {
      return db.execute('CREATE TABLE user_Name(name TEXT)');
    },
    version: 1,
  );
  return db;
}

class UsernameNotifier extends StateNotifier<String> {
  UsernameNotifier() : super('Name');

  Future<void> loaddetails() async {
    final db = await _openDatabase();
    final data = await db.query('user_Name');
    if (data.isNotEmpty) {
      state = data[0]['name'] as String;
    }// for fixing the error where name appear in brackets i.e. (satyam) like this insted of satyam
  }

  void getUserName(String userDetails) async {
    state = userDetails;
    final db = await _openDatabase();
    db.insert('user_Name', {'name': userDetails});
  }
}

final userDetailProvider =
    StateNotifierProvider<UsernameNotifier, String>((ref) {
  return UsernameNotifier();
});
