import 'package:flutter/material.dart';
import 'package:passgen/data/avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passgen/provider/avatarselector_provider.dart';

class AddAvatar extends ConsumerStatefulWidget {
  const AddAvatar({super.key});

  @override
  ConsumerState<AddAvatar> createState() => _AddAvatarState();
}

class _AddAvatarState extends ConsumerState<AddAvatar> {
  List<Color> avatarColors = List.generate(6, (index) => Colors.blue);
  int selectedAvatarIndex = 0;

  void selectAvatar(int index) {
    setState(() {
      for (int i = 0; i < avatarColors.length; i++) {
        avatarColors[i] = i == index ? Colors.green : Colors.blue;
      }
      selectedAvatarIndex = index;
    });
  }

  // void _saveAvatar() {
  //   ref
  //       .read(userprofileprovider.notifier)
  //       .getUserAvatar(availableAvatar[Image.asset('assets/images/Img ($selectedAvatarIndex).png')]);
  // }
  void _saveAvatar() {
    ref
        .read(userprofileprovider.notifier)
        .getUserAvatar(availableAvatar[selectedAvatarIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        // mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 30),
          const Text(
            'Select Avatar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 320,
            child: GridView.builder(
              itemCount: avatarColors.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => selectAvatar(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: CircleAvatar(
                      backgroundColor: avatarColors[index],
                      child: CircleAvatar(
                        backgroundColor: Colors.blue[200],
                        radius: 35,
                        child: Image.asset(
                          availableAvatar[index],
                          height: 60,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _saveAvatar();
              Navigator.of(context).pop();
            },
            style: ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(
                    Theme.of(context).colorScheme.primary.withOpacity(.7)),
                padding: const MaterialStatePropertyAll(
                    EdgeInsets.only(top: 20, bottom: 20, left: 80, right: 80))),
            child: const Text(
              'Select',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}
