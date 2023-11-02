import 'package:flutter/material.dart';
import 'package:passgen/provider/avatarselector_provider.dart';
import 'package:passgen/provider/username_provider.dart';
import 'package:passgen/screen/tabscreen.dart';
import 'package:passgen/widget/addavatar.dart';
import 'package:passgen/screen/homescreen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final namecontroller = TextEditingController();
  @override
  void dispose() {
    namecontroller.dispose();
    super.dispose();
  }

  void _saveDetails() {
    ref.read(userDetailProvider.notifier).getUserName(namecontroller.text);
    debugPrint(namecontroller.text);
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
              onTap: () => showModalBottomSheet(
                // shape: const RoundedRectangleBorder(
                //     borderRadius:
                //         BorderRadius.vertical(top: Radius.circular(30))),
                context: context,
                builder: (context) => const AddAvatar(),
              ),
              child: CircleAvatar(
                radius: 50,
                child: avatarInfo,
              ),
            ),
            const SizedBox(height: 50),
            TextField(
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
                onPressed: _saveDetails,
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
