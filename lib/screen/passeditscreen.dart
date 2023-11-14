import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passgen/data/platformimage.dart';
import 'package:passgen/model/passcard.dart';
import 'package:passgen/provider/savepass_provider.dart';

class PassEditScreen extends ConsumerStatefulWidget {
  const PassEditScreen({super.key, required this.passwordCard});
  final PasswordCard passwordCard;

  @override
  ConsumerState<PassEditScreen> createState() => _PassEditState();
}

class _PassEditState extends ConsumerState<PassEditScreen> {
  final Map<String, String> platformImages = platformImage;

  @override
  void initState() {
    super.initState();
    platformController =
        TextEditingController(text: widget.passwordCard.platformname);
    userIdController = TextEditingController(text: widget.passwordCard.userid);
    _currentSliderValue = widget.passwordCard.length.toDouble();
    generate = widget.passwordCard.generatedpassword;
  }

  double _currentSliderValue = 8;
  String platformname = 'Platform Name';
  String userId = 'user.example@gmail.com';
  TextEditingController? platformController;
  TextEditingController? userIdController;
  String generate = '';
  // @override
  // void initState() {
  //   super.initState();
  //   platformController = TextEditingController();
  //   userIdController = TextEditingController();
  // }

  // @override
  // void dispose() {
  //   platformController!.dispose();
  //   userIdController!.dispose();
  //   super.dispose();
  // }

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

  void _updateInfo() async {
    final updatedPasswordCard = PasswordCard(
      id: widget.passwordCard.id, // Preserve the original ID
      addTime: DateTime.now(),
      platformname: platformController!.text,
      userid: userIdController!.text,
      length: _currentSliderValue,
      generatedpassword: generate,
    );

    await ref
        .read(passcardprovider.notifier)
        .updatePassword(updatedPasswordCard);

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Information Updated.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    String imageAsset =
        platformImages[platformController!.text] ?? 'unknown.png';
    List<Color> colorAsset = platformColor[platformController!.text] ??
        const [
          Color.fromARGB(255, 255, 239, 99),
          Colors.red,
        ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Update Info',
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
                  title: Text(platformController!.text),
                  subtitle: Text(userIdController!.text),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 40),
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
                    controller: platformController,
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
                padding: EdgeInsets.only(left: 40),
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
                Text(
                  'Length',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
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
          Text(
            'Password',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
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
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            )),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              children: [
                const SizedBox(width: 30),
                ElevatedButton.icon(
                  style: const ButtonStyle(
                    padding: MaterialStatePropertyAll(
                      EdgeInsets.only(top: 20, bottom: 20, left: 30, right: 30),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      generate = generatePassword(_currentSliderValue);
                    });
                  },
                  icon: const Icon(Icons.new_label_outlined),
                  label: const Text('New', style: TextStyle(fontSize: 15)),
                ),
                const SizedBox(width: 30),
                ElevatedButton.icon(
                    style: const ButtonStyle(
                      padding: MaterialStatePropertyAll(
                        EdgeInsets.only(
                            top: 20, bottom: 20, left: 30, right: 30),
                      ),
                    ),
                    onPressed: () {
                      _updateInfo();
                    },
                    icon: const Icon(
                      Icons.update,
                      size: 26,
                    ),
                    label: const Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    )),
              ],
            ),
          )
        ]),
      ),
    );
  }
}
