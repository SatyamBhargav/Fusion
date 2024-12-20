import 'dart:io';
import 'package:flutter/material.dart';
import 'package:passgen/model/passcard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:excel/excel.dart';
// import 'package:path_provider/path_provider.dart' as syspath;

Future<Database> _openDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  final db = await sql.openDatabase(
    path.join(dbPath, 'passGen.db'),
    onCreate: (db, version) {
      return db.execute(
          'CREATE TABLE user_Detail(id TEXT ,platformName TEXT PRIMARY KEY,userId TEXT,length REAL,genpassword TEXT,addedTime INTEGER)');
    },
    version: 2,
  );
  return db;
}

class SavePasswordNotifier extends StateNotifier<List<PasswordCard>> {
  SavePasswordNotifier() : super(const []);

  Future<void> loaddetails() async {
    final db = await _openDatabase();
    final data = await db.query('user_Detail', orderBy: 'addedTime DESC');
    final details = data
        .map((row) => PasswordCard(
            id: row['id'] as String,
            addTime:
                DateTime.fromMillisecondsSinceEpoch(row['addedTime'] as int),
            platformname: row['platformName'] as String,
            userid: row['userId'] as String,
            length: row['length'] as num,
            generatedpassword: row['genpassword'] as String))
        .toList();
    state = details;
  }

  Future<void> printData() async {
    var excel = Excel.createExcel();
    var sheet = excel['Sheet1'];
    final db = await _openDatabase();
    final data = await db.query('user_Detail');
    sheet.appendRow([
      TextCellValue('Platform Name'),
      TextCellValue('Email'),
      TextCellValue('Password')
    ]);
    for (var row in data) {
      sheet.appendRow([
        TextCellValue(row['platformName'] as String),
        TextCellValue(row['userId'] as String),
        TextCellValue(row['genpassword'] as String)
      ]);
    }

    String outputFile = "/storage/emulated/0/Download/Password.xlsx";

    //stopwatch.reset();
    List<int>? fileBytes = excel.save();
    //print('saving executed in ${stopwatch.elapsed}');
    if (fileBytes != null) {
      File(path.join(outputFile))
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
    }
  }

  void generatedPassword(PasswordCard passcard) async {
    // ignore: unused_local_variable
    final passIsAdded = state.contains(passcard);
    final int timestamp = passcard.addTime.millisecondsSinceEpoch;

    final db = await _openDatabase();
    db.insert('user_Detail', {
      'id': passcard.id,
      'addedTime': timestamp,
      'platformName': passcard.platformname,
      'userId': passcard.userid,
      'length': passcard.length,
      'genpassword': passcard.generatedpassword,
    });

    state = [passcard, ...state];
  }

  Future<void> _deletePassword(String id) async {
    final db = await _openDatabase();
    await db.delete('user_Detail', where: 'id = ?', whereArgs: [id]);
  }

  void deletePassword(String id) async {
    await _deletePassword(id);
    state = state.where((password) => password.id != id).toList();
  }

  Future<void> updatePassword(PasswordCard updatedPasswordCard) async {
    final db = await _openDatabase();

    await db.update(
      'user_Detail',
      {
        'addedTime': updatedPasswordCard.addTime.millisecondsSinceEpoch,
        'platformName': updatedPasswordCard.platformname,
        'userId': updatedPasswordCard.userid,
        'length': updatedPasswordCard.length,
        'genpassword': updatedPasswordCard.generatedpassword,
      },
      where: 'id = ?',
      whereArgs: [updatedPasswordCard.id],
    );

    state = state.map((password) {
      return password.id == updatedPasswordCard.id
          ? updatedPasswordCard
          : password;
    }).toList();
  }

  void filtername(String pName) async {
    final db = await _openDatabase();
    List<Map<String, dynamic>> data;

    if (pName.isEmpty) {
      data = await db.query('user_Detail', orderBy: 'addedTime DESC');
    } else {
      data = await db.query('user_Detail',
          where: 'platformName LIKE ?', whereArgs: ['%$pName%']);
    }

    final details = data
        .map((row) => PasswordCard(
            id: row['id'] as String,
            addTime:
                DateTime.fromMillisecondsSinceEpoch(row['addedTime'] as int),
            platformname: row['platformName'] as String,
            userid: row['userId'] as String,
            length: row['length'] as num,
            generatedpassword: row['genpassword'] as String))
        .toList();

    state = details;
  }

  void uploadData(String excelFilePath, context) async {
    //********************************* Upload Excel Data **************************************/
    var file = File(excelFilePath);
    var bytes = await file.readAsBytes();
    var excel = Excel.decodeBytes(bytes);

    // Parse Excel data
    var sheet = excel['Sheet1'];
    List<List<dynamic>> excelData = [];

    // Iterate over rows, starting from the second row (index 1)
    for (var row in sheet.rows) {
      // Extract only the necessary columns (Platform, Email, Password)
      var rowData = [
        row[0]?.value, // Platform
        row[1]?.value, // Email
        row[2]?.value, // Password
      ];

      // Add row data to excelData if it's not null or empty
      if (rowData.every((cell) => cell != null && cell.toString().isNotEmpty)) {
        excelData.add(rowData);
      }
    }
    final db = await _openDatabase();
    try {
      for (var i = 1; i < excelData.length; i++) {
        await db.insert('user_Detail', {
          'id': uuid.v4(),
          'addedTime': DateTime.now().microsecondsSinceEpoch,
          'platformName': excelData[i][0].toString(),
          'userId': excelData[i][1].toString(),
          'length': '0',
          'genpassword': excelData[i][2].toString(),
        });
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password Added Successfully'),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.horizontal,
        ),
      );
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        // Handle UNIQUE constraint violation error here
        // log(e.toString());
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sheet contain duplicate platform name'),
            behavior: SnackBarBehavior.floating,
            dismissDirection: DismissDirection.horizontal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error Occurred! Please try again'),
            behavior: SnackBarBehavior.floating,
            dismissDirection: DismissDirection.horizontal,
          ),
        );
      }
    }

    // loaddetails();
    //********************************* Value from the DB *****************************************/

    //   // Query the database
    //   List<Map<String, dynamic>> rows = await db.query('user_Detail');

    //   // Print the data
    //   for (Map<String, dynamic> row in rows) {
    //     print(row);
    //   }

    //   // Close the database connection
    //   await db.close();
  }
}

final passcardprovider =
    StateNotifierProvider<SavePasswordNotifier, List<PasswordCard>>((ref) {
  return SavePasswordNotifier();
});


/**
In the context of SQL queries, "platformName LIKE ?" is a SQL statement that uses the LIKE operator to perform a partial string matching or pattern matching. 
The ? is a placeholder for a parameterized value that will be provided later. 
Here's an explanation of how it works:
platformName is the name of the column in the database table that you want to search.
LIKE is an SQL operator used for pattern matching. It is typically used to match a specified pattern within a text field. 
In this case, it is used to match a pattern within the platformName column.
? is a parameter placeholder. It's often used in parameterized queries to safely insert values into the SQL query. 
The actual value that should match the pattern will be provided separately when you execute the query.
When you use ? as a placeholder, you can later bind a value to it using the whereArgs parameter in your SQL query function.
 */


 
/**
  // Code for the main.dart

    Future<void> checkDatabase() async {
    final db = await _openDatabase();

    try {
      final tables = await db.query("sqlite_master", where: "type = 'table'");
      if (tables.isNotEmpty) {
        for (var table in tables) {
          print("Table Name: ${table['name']}");
        }
      } else {
        print("No tables found in the database.");
      }
    } catch (e) {
      print("Database or table does not exist: $e");
    }
  }

  Future<bool> isDataWritten() async {
    final db = await _openDatabase();

    final data = await db.query('user_Detail');

    return data.isNotEmpty;
  }
 */
