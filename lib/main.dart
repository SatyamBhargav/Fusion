import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passgen/provider/savepass_provider.dart';
import 'package:passgen/screen/tabscreen.dart';
import 'package:passgen/widget/addavatar.dart';
import 'package:passgen/screen/homescreen.dart';
import 'package:passgen/screen/welcomescreen.dart';

void main() async {
  runApp(const ProviderScope(child: MyApp()));
  /** 
   // To check if table is created in database or not.
   
  Initialize SavePasswordNotifier
  final savePasswordNotifier = SavePasswordNotifier();

  Call checkDatabase to verify the database and table
  savePasswordNotifier.checkDatabase();

  // To check wether data is being written into the table or not.

  await savePasswordNotifier.loaddetails();
  final dataWritten = await savePasswordNotifier.isDataWritten();

  if (dataWritten) {
    print("Data is written to the table.");
  } else {
    print("No data in the table.");
  }
  */
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const HomeScreen(),
      home: TabScreen(),
      // home: const WelcomeScreen(),
      // home: PassGen(),
      // home: AddAvatar(),
    );
  }
}
