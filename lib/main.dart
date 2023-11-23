import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passgen/provider/theme_provider.dart';
import 'package:passgen/screen/passgenscreen.dart';
import 'package:passgen/screen/profilescreen.dart';
import 'package:passgen/screen/tabscreen.dart';
import 'package:passgen/screen/welcomescreen.dart';

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
    super.initState();
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
                  scaffoldBackgroundColor: Colors.black,
                  textTheme: const TextTheme(
                      titleMedium:
                          TextStyle(color: Colors.white, fontSize: 20)),
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
                        titleMedium:
                            TextStyle(color: Colors.black, fontSize: 20)),
                    colorScheme:
                        ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                    bottomNavigationBarTheme:
                        const BottomNavigationBarThemeData(
                            selectedIconTheme:
                                IconThemeData(color: Colors.deepPurple),
                            unselectedIconTheme:
                                IconThemeData(color: Color(0xff696375)))

                    // iconTheme: IconThemeData().copyWith(),
                    ),

                //default
                // theme: ThemeData(
                //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                //   useMaterial3: true,
                // ),
                home: const WelcomeScreen(),
                // home: const HomeScreen(),
                // home: const TabScreen(),
                // home: ManualGenScreen(),
                // home: PassEditScreen(passwordCard: ,),
                // home: PassGenScreen(),
                // home: const WelcomeScreen(),
                // home: PassGen(),
                // home: AddAvatar(),
                // home: ProfileScreen(),
              ));
  }
}
