import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passgen/provider/theme_provider.dart';
import 'package:passgen/screen/passgenscreen.dart';
import 'package:passgen/screen/tabscreen.dart';
import 'package:passgen/screen/welcomescreen.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

// var kColorScheme =
//     ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 96, 59, 181));

var kDarkColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.deepPurpleAccent,
  brightness: Brightness.dark,
);

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late Future<void> _values;
  @override
  void initState() {
    _values = ref.read(themeProvider.notifier).loaddetails();
    checkFirstTime();
    super.initState();
  }

  Future<Widget> checkFirstTime() async {
    String namedatabase = path.join(await getDatabasesPath(), 'userName.db');
    bool exist = await databaseExists(namedatabase);

    if (exist) {
      // ignore: use_build_context_synchronously
      return const TabScreen();
    } else {
      return const WelcomeScreen();
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final datavalue = ref.watch(themeProvider);

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return FutureBuilder(
        future: _values,
        builder: (context, snapshot) => snapshot.connectionState ==
                ConnectionState.waiting
            ? const MaterialApp(
                home: Scaffold(
                    body: Center(
                  child: CircularProgressIndicator(),
                )),
              )
            : MaterialApp(
                routes: {'/passgenscreen': (context) => const PassGenScreen()},
                themeMode: datavalue ? ThemeMode.dark : ThemeMode.light,
                darkTheme: ThemeData.dark().copyWith(
                  colorScheme: kDarkColorScheme,
                  scaffoldBackgroundColor: const Color(0xff121212),
                  textTheme: const TextTheme(
                      titleMedium:
                          TextStyle(color: Colors.white, fontSize: 20)),
                  listTileTheme: const ListTileThemeData(
                      iconColor: Colors.white, textColor: Colors.black),
                  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                    backgroundColor: Color(0xff1d1d1d),
                    unselectedItemColor: Color(0xff696375),
                    selectedItemColor: Colors.deepPurpleAccent,
                  ),
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
                    textTheme: const TextTheme(
                        titleMedium:
                            TextStyle(color: Colors.black, fontSize: 20)),
                    colorScheme:
                        ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                    bottomNavigationBarTheme:
                        const BottomNavigationBarThemeData(
                      backgroundColor: Color.fromARGB(255, 229, 215, 255),
                      selectedIconTheme:
                          IconThemeData(color: Colors.deepPurple),
                      unselectedIconTheme: IconThemeData(
                        color: Color(0xff696375),
                      ),
                    )),
                home: FutureBuilder(
                  future: checkFirstTime(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else {
                      return snapshot.data!;
                    }
                  },
                ),
              ));
  }
}



  /** 
   * use the below code in main function
   * 
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
