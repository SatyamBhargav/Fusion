import 'package:flutter/material.dart';
import 'package:passgen/provider/avatarselector_provider.dart';
import 'package:passgen/provider/username_provider.dart';
import 'package:passgen/screen/tabscreen.dart';
import 'package:passgen/widget/addavatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  void initState() {
    checkFirstTime();
    // _userNameFuture = ref.read(userDetailProvider.notifier).openDatabase();
    super.initState();
  }

  Future<void> checkFirstTime() async {
    final database = await openDatabase(
      path.join(await getDatabasesPath(), 'intro_screen.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE intro_screen(flag INTEGER)',
        );
      },
      version: 1,
    );

    List<Map<String, dynamic>> result =
        await database.rawQuery('SELECT * FROM intro_screen');
    bool isFirstTime = result.isEmpty;

    if (isFirstTime) {
      // Show your introductory screen here

      // Once the screen is shown, insert a record to indicate it's not the first time
      await database.rawInsert('INSERT INTO intro_screen(flag) VALUES(1)');
    } else {
      // Navigate to the main screen or home screen
      Future.delayed(Duration(microseconds: 2000), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => TabScreen()),
        );
      });
    }
  }

  final namecontroller = TextEditingController();
  @override
  void dispose() {
    namecontroller.dispose();
    super.dispose();
  }

  void _saveDetails() {
    ref.read(userDetailProvider.notifier).getUserName(namecontroller.text);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const TabScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final avatarInfo = ref.watch(userprofileprovider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                showModalBottomSheet(
                  // shape: const RoundedRectangleBorder(
                  //     borderRadius:
                  //         BorderRadius.vertical(top: Radius.circular(30))),
                  context: context,
                  builder: (context) => const AddAvatar(),
                );
              },
              child: CircleAvatar(
                radius: 50,
                child: avatarInfo,
              ),
            ),
            const SizedBox(height: 50),
            TextField(
              style: Theme.of(context).textTheme.titleMedium,
              textCapitalization: TextCapitalization.words,
              controller: namecontroller,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                  hintText: 'User Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)))),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(
                        Theme.of(context).colorScheme.primary.withOpacity(.8))),
                onPressed: () {
                  _saveDetails();
                },
                child: const Text(
                  'Welcome',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ))
          ],
        ),
      ),
    );
  }
}
