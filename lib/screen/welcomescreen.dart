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
  // @override
  // void initState() {
  //   checkFirstTime();
  //   super.initState();
  // }

  // Future<void> checkFirstTime() async {
  //   String namedatabase = path.join(await getDatabasesPath(), 'userName.db');
  //   bool exist = await databaseExists(namedatabase);
  //   // debugPrint('nameDatabase value - $exist');

  //   if (exist) {
  //     // ignore: use_build_context_synchronously
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(builder: (context) => const TabScreen()),
  //     );
  //   }
  // }

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
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  /**
                    Clip.antiAliasWithSaveLayer makes it so that if the content of the modal sheet is scrollable, 
                    the scrollable content will also be clipped to the modal's 
                    border radius if anyone was wondering.
              
                   */
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30))),
                  context: context,
                  builder: (context) => const AddAvatar(),
                );
              },
              child: CircleAvatar(
                radius: 50,
                child: Image.asset(
                  avatarInfo,
                  height: 60,
                ),
              ),
            ),
            const SizedBox(height: 50),
            TextField(
              style: Theme.of(context).textTheme.titleMedium,
              textCapitalization: TextCapitalization.words,
              controller: namecontroller,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                  hintText: 'What Should I Call You ?',
                  hintStyle: TextStyle(fontSize: 15),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)))),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
                style: const ButtonStyle(
                    backgroundColor:
                        MaterialStatePropertyAll(Colors.deepPurple)),
                onPressed: () {
                  if (namecontroller.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('What should I call you?')));
                  } else if (avatarInfo == 'assets/images/default.png') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please select an avatar')));
                  } else {
                    _saveDetails();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'Welcome',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(color: Colors.white),
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
