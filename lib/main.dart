import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passgen/provider/savepass_provider.dart';
import 'package:passgen/screen/passgenscreen.dart';
import 'package:passgen/screen/tabscreen.dart';
import 'package:passgen/widget/addavatar.dart';
import 'package:passgen/screen/homescreen.dart';
import 'package:passgen/screen/welcomescreen.dart';

// var kColorScheme =
//     ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 96, 59, 181));

var kDarkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 5, 99, 125),
  brightness: Brightness.dark,
);

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
      // themeMode: ThemeMode.dark,
      themeMode: ThemeMode.light,
      darkTheme: ThemeData.dark().copyWith(
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
          // listTileTheme: ListTileThemeData(iconColor: Colors.green),
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              selectedIconTheme: IconThemeData(color: Colors.deepPurple),
              unselectedIconTheme: IconThemeData(color: Color(0xff696375)))

          // iconTheme: IconThemeData().copyWith(),
          ),
      // theme: ThemeData().copyWith(
      //   useMaterial3: true,
      //   colorScheme: kColorScheme,
      //   appBarTheme: const AppBarTheme().copyWith(
      //     backgroundColor: kColorScheme.onPrimaryContainer,
      //     foregroundColor: kColorScheme.primaryContainer,
      //   ),
      //   cardTheme: const CardTheme().copyWith(
      //     color: kColorScheme.secondaryContainer,
      //     margin: const EdgeInsets.symmetric(
      //       horizontal: 16,
      //       vertical: 8,
      //     ),
      //   ),
      //   elevatedButtonTheme: ElevatedButtonThemeData(
      //     style: ElevatedButton.styleFrom(
      //         backgroundColor: kColorScheme.primaryContainer),
      //   ),
      //   textTheme: ThemeData().textTheme.copyWith(
      //         titleLarge: TextStyle(
      //           fontWeight: FontWeight.bold,
      //           color: kColorScheme.onSecondaryContainer,
      //           fontSize: 16,
      //         ),
      //       ),
      // ),
      // title: 'Password Generator',

      //default
      // theme: ThemeData(
      //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      //   useMaterial3: true,
      // ),
      // home: const HomeScreen(),
      home: TabScreen(),
      // home: PassGenScreen(),
      // home: const WelcomeScreen(),
      // home: PassGen(),
      // home: AddAvatar(),
    );
  }
}
