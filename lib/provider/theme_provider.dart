import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart' as path;

Future<Database> _openDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  final db = await sql.openDatabase(
    path.join(dbPath, 'userThememode.db'),
    onCreate: (db, version) {
      return db.execute('CREATE TABLE user_Theme(name INTEGER PRIMARY KEY)');
    },
    version: 1,
  );
  return db;
}

class ThemeProviderNotifier extends StateNotifier<bool> {
  ThemeProviderNotifier() : super(false);

  Future<void> loaddetails() async {
    final db = await _openDatabase();
    final data = await db.query('user_Theme');
    if (data.isNotEmpty) {
      final details = data.first['name'] as int;
      if (details == 1) {
        state = true;
      } else {
        state = false;
      }
    }
  }

  void setTheme(bool name) async {
    state = name;
    debugPrint('setTheme name - $name.toString()');
    final db = await _openDatabase();
    final data = await db.query('user_Theme');
    if (data.isEmpty) {
      if (name == true) {
        db.insert('user_Theme', {'name': 1});
      } else {
        db.insert('user_Theme', {'name': 0});
      }
    } else {
      if (data.first['name'] == 1) {
        db.update('user_Theme', {'name': 0});
      } else {
        db.update('user_Theme', {'name': 1});
      }
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeProviderNotifier, bool>(
    (ref) => ThemeProviderNotifier());
