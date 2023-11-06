import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passgen/screen/tabscreen.dart';
import 'package:passgen/widget/addavatar.dart';
import 'package:passgen/screen/homescreen.dart';
import 'package:passgen/screen/welcomescreen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
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
