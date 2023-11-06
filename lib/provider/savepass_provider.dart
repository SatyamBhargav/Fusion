import 'package:passgen/model/passcard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:path_provider/path_provider.dart' as syspath;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';

Future<Database> _openDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  final db = await sql.openDatabase(
    path.join(dbPath, 'passGen.db'),
    onCreate: (db, version) {
      return db.execute(
          'CREATE TABLE user_Detail(id TEXT PRIMARY KEY,platformName TEXT,userId TEXT,length REAL,genpassword TEXT)');
    },
    version: 2,
  );
  return db;
}

class SavePasswordNotifier extends StateNotifier<List<PasswordCard>> {
  SavePasswordNotifier() : super(const []);

  Future<void> loaddetails() async {
    final db = await _openDatabase();
    final data = await db.query('user_Detail');
    final details = data
        .map((row) => PasswordCard(
            id: row['id'] as String,
            platformname: row['platformName'] as String,
            userid: row['userId'] as String,
            length: row['length'] as num,
            generatedpassword: row['genpassword'] as String))
        .toList();
    state = details;
  }

  void generatedPassword(PasswordCard passcard) async {
    // ignore: unused_local_variable
    final passIsAdded = state.contains(passcard);

    final db = await _openDatabase();
    db.insert('user_Detail', {
      'id': passcard.id,
      'platformName': passcard.platformname,
      'userId': passcard.userid,
      'length': passcard.length,
      'genpassword': passcard.generatedpassword,
    });

    state = [passcard, ...state];
  }

  // Future<void> checkDatabase() async {
  //   final db = await _openDatabase();

  //   try {
  //     final tables = await db.query("sqlite_master", where: "type = 'table'");
  //     if (tables.isNotEmpty) {
  //       for (var table in tables) {
  //         print("Table Name: ${table['name']}");
  //       }
  //     } else {
  //       print("No tables found in the database.");
  //     }
  //   } catch (e) {
  //     print("Database or table does not exist: $e");
  //   }
  // }

  // Future<bool> isDataWritten() async {
  //   final db = await _openDatabase();

  //   final data = await db.query('user_Detail');

  //   return data.isNotEmpty;
  // }

  void filtername(String pName) {
    List<PasswordCard> result = [];
    if (pName.isEmpty) {
      result = state;
    } else {
      result = state
          .where((element) => element.platformname
              .toString()
              .toLowerCase()
              .contains(pName.toLowerCase()))
          .toList();
    }
    state = result;
  }
}

final passcardprovider =
    StateNotifierProvider<SavePasswordNotifier, List<PasswordCard>>((ref) {
  return SavePasswordNotifier();
});
