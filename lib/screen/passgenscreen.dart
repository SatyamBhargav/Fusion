import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passgen/model/passcard.dart';
import 'package:passgen/provider/savepass_provider.dart';

class PassGenScreen extends ConsumerStatefulWidget {
  const PassGenScreen({super.key});

  @override
  ConsumerState<PassGenScreen> createState() => _PassGenState();
}

class _PassGenState extends ConsumerState<PassGenScreen> {
  double _currentSliderValue = 8;
  String platformname = 'Facebook';
  String userId = 'user.example@gmail.com';
  TextEditingController? platformController;
  TextEditingController? userIdController;
  String generate = '';

  @override
  void initState() {
    super.initState();
    platformController = TextEditingController();
    userIdController = TextEditingController();
  }

  @override
  void dispose() {
    platformController!.dispose();
    userIdController!.dispose();
    super.dispose();
  }

  String generatePassword(double length) {
    const String uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
    const String digits = '0123456789';
    const String specialChars = '!@#\$%^&*()_-+=<>?';

    const String allChars =
        uppercaseChars + lowercaseChars + digits + specialChars;

    final Random random = Random();
    String password = '';

    for (int i = 0; i < length; i++) {
      final int randomIndex = random.nextInt(allChars.length);
      password += allChars[randomIndex];
    }

    return password;
  }

  void _savePassword() {
    ref.read(passcardprovider.notifier).generatedPassword(PasswordCard(
        platformname: platformname,
        userid: userId,
        length: _currentSliderValue,
        generatedpassword: generate));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Password Generator',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.snapchat,
                    size: 45,
                  ),
                  title: Text(platformname),
                  subtitle: Text(userId),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 40),
                  child: Text(
                    'Platform',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15, right: 70),
                    child: TextField(
                      onChanged: (value) {
                        if (value == '') {
                          setState(() {
                            platformname = 'Facebook';
                          });
                        } else {
                          setState(() {
                            platformname = value;
                          });
                        }
                      },
                      controller: platformController,
                      decoration: const InputDecoration(
                        hintText: 'Facebook',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 40),
                  child: Text(
                    'User id',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 30, right: 70),
                    child: TextField(
                      onChanged: (value) {
                        if (value == '') {
                          setState(() {
                            userId = 'user.example@gmail.com';
                          });
                        } else {
                          setState(() {
                            userId = value;
                          });
                        }
                      },
                      controller: userIdController,
                      decoration: const InputDecoration(
                        hintText: 'user.example@gmail.com',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  const Text(
                    'Length',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 268,
                    child: Slider(
                      value: _currentSliderValue,
                      max: 40,
                      divisions: 5,
                      label: _currentSliderValue.round().toString(),
                      onChanged: (double value) {
                        setState(() {
                          _currentSliderValue = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Password',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Container(
              height: 80,
              width: 320,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(.3),
                  borderRadius: BorderRadius.circular(20)),
              child: Center(
                  child: Text(
                generate,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(
                        Theme.of(context).colorScheme.primary),
                    padding: const MaterialStatePropertyAll(EdgeInsets.only(
                        top: 20, bottom: 20, right: 120, left: 120))),
                onPressed: () {
                  setState(() {
                    generate = generatePassword(_currentSliderValue);
                  });
                },
                child: const Text(
                  'Generate',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                )),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  const SizedBox(width: 30),
                  ElevatedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: generate));
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Copied to clipboard.')));
                        //Fluttertoast.showToast(msg: 'Copied to clipboard.');
                      },
                      style: const ButtonStyle(
                          padding: MaterialStatePropertyAll(EdgeInsets.only(
                              top: 20, bottom: 20, left: 30, right: 30))),
                      icon: const Icon(Icons.copy_sharp),
                      label: const Text(
                        'Copy',
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      )),
                  const SizedBox(width: 30),
                  ElevatedButton.icon(
                      style: const ButtonStyle(
                          padding: MaterialStatePropertyAll(EdgeInsets.only(
                              top: 20, bottom: 20, left: 30, right: 30))),
                      onPressed: () {
                        _savePassword();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password Saved.')));
                      },
                      icon: const Icon(
                        Icons.save_outlined,
                        size: 26,
                      ),
                      label: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      )),
                ],
              ),
            )
          ]),
        ),
      ),
    );
  }
}
