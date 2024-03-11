import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passgen/data/platformimage.dart';
import 'package:passgen/model/passcard.dart';
import 'package:passgen/provider/savepass_provider.dart';

class ManualGenScreen extends ConsumerStatefulWidget {
  const ManualGenScreen({super.key});

  @override
  ConsumerState<ManualGenScreen> createState() => _ManualGenState();
}

class _ManualGenState extends ConsumerState<ManualGenScreen> {
  final _newPassword = TextEditingController();
  final Map<String, String> platformImages = platformImage;

  final double _currentSliderValue = 0;
  String platformname = 'Platform Name';
  String userId = 'user.example@gmail.com';
  final _platformController = TextEditingController();
  final _userIdController = TextEditingController();
  String generate = '';

  @override
  void dispose() {
    _platformController.dispose();
    _userIdController.dispose();
    _newPassword.dispose();
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
    if (platformname == 'Platform Name' ||
        userId == 'user.example@gmail.com' ||
        _newPassword.text == '') {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter valid value before saving'),
        dismissDirection: DismissDirection.horizontal,
      ));
    } else {
      ref.read(passcardprovider.notifier).generatedPassword(
            PasswordCard(
                addTime: DateTime.now(),
                platformname: platformname,
                userid: userId,
                length: _currentSliderValue,
                generatedpassword: _newPassword.text),
          );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password Saved.'),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
      ));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    String imageAsset =
        platformImages[platformname.trim().toLowerCase()] ?? 'unknown.png';
    List<Color> colorAsset = platformColor[platformname.trim().toLowerCase()] ??
        const [
          Color.fromARGB(255, 255, 239, 99),
          Colors.red,
        ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Add a new one',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Card(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                      colors: colorAsset,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                child: ListTile(
                  leading: Image.asset(
                    'assets/pImage/$imageAsset',
                    height: 50,
                  ),
                  title: Text(platformname),
                  subtitle: Text(userId),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  'Platform',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 15, right: 70),
                  child: TextField(
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 15),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (value) {
                      if (value == '') {
                        setState(() {
                          platformname = 'Platform Name';
                        });
                      } else {
                        setState(() {
                          platformname = value;
                        });
                      }
                    },
                    controller: _platformController,
                    decoration: const InputDecoration(
                      hintText: 'Platform Name',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  'User id',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 30, right: 70),
                  child: TextField(
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 15),
                    keyboardType: TextInputType.emailAddress,
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
                    controller: _userIdController,
                    decoration: const InputDecoration(
                      hintText: 'user.example@gmail.com',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            'Password',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: TextField(
              controller: _newPassword,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                  hintText: 'Current Password',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
              style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(Colors.deepPurple),
                  padding: MaterialStatePropertyAll(
                    EdgeInsets.only(top: 20, bottom: 20, right: 120, left: 120),
                  )),
              onPressed: _savePassword,
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 20, color: Colors.white),
              )),
          const SizedBox(height: 30),
          ElevatedButton.icon(
              onPressed: () async {
                if (_newPassword.text == '') {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nothing to copy'),                                        dismissDirection:
                                            DismissDirection.horizontal,));
                } else {
                  await Clipboard.setData(
                      ClipboardData(text: _newPassword.text));
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                }
              },
              style: ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(
                    Theme.of(context).colorScheme.background),
                padding: const MaterialStatePropertyAll(
                    EdgeInsets.only(top: 20, bottom: 20, left: 30, right: 30)),
              ),
              icon: const Icon(Icons.copy_sharp),
              label: const Text(
                'Copy',
                style: TextStyle(
                  fontSize: 15,
                ),
              )),

        ]),
      ),
    );
  }
}
