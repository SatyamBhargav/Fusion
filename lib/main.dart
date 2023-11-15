import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passgen/provider/savepass_provider.dart';
import 'package:passgen/screen/manualgenscreen.dart';
import 'package:passgen/screen/passeditscreen.dart';
import 'package:passgen/screen/passgenscreen.dart';
import 'package:passgen/screen/profilescreen.dart';
import 'package:passgen/screen/tabscreen.dart';
import 'package:passgen/widget/addavatar.dart';
import 'package:passgen/screen/homescreen.dart';
import 'package:passgen/screen/welcomescreen.dart';
import 'package:riverpod/riverpod.dart';

// var kColorScheme =
//     ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 96, 59, 181));

var kDarkColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.deepPurpleAccent,
  brightness: Brightness.dark,
);

void main() {
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

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      routes: {'/passgenscreen': (context) => PassGenScreen()},
      themeMode: ref.watch(themeModeProvider),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: const TextTheme(
            titleMedium: TextStyle(color: Colors.white, fontSize: 20)),
        listTileTheme: const ListTileThemeData(
            iconColor: Colors.white, textColor: Colors.black),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            unselectedItemColor: Color(0xff696375),
            selectedItemColor: Colors.deepPurple),
        colorScheme: kDarkColorScheme,
        useMaterial3: true,
        cardTheme: const CardTheme().copyWith(
          color: kDarkColorScheme.secondaryContainer,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kDarkColorScheme.primaryContainer,
            foregroundColor: kDarkColorScheme.onPrimaryContainer,
          ),
        ),
      ),
      theme: ThemeData().copyWith(
          useMaterial3: true,
          textTheme: const TextTheme(
              titleMedium: TextStyle(color: Colors.black, fontSize: 20)),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              selectedIconTheme: IconThemeData(color: Colors.deepPurple),
              unselectedIconTheme: IconThemeData(color: Color(0xff696375)))

          // iconTheme: IconThemeData().copyWith(),
          ),

      //default
      // theme: ThemeData(
      //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      //   useMaterial3: true,
      // ),
      home: WelcomeScreen(),
      // home: const HomeScreen(),
      // home: const TabScreen(),
      // home: ManualGenScreen(),
      // home: PassEditScreen(),
      // home: PassGenScreen(),
      // home: const WelcomeScreen(),
      // home: PassGen(),
      // home: AddAvatar(),
      // home: ProfileScreen(),
    );
  }
}
