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

  void _saveAvatar() {
    ref
        .read(userprofileprovider.notifier)
        .getUserAvatar(availableAvatar[selectedAvatarIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        // mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 30),
          Text(
            'Select Avatar',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: avatarColors.length,
              // gridDelegate:
              //     const SliverGridDelegateWithFixedCrossAxisCount(
              //         crossAxisCount: 3),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    selectAvatar(index);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: CircleAvatar(
                      backgroundColor: avatarColors[index],
                      radius: 40,
                      child: CircleAvatar(
                        backgroundColor: Colors.blue[200],
                        radius: 35,
                        child: Image.asset(
                          availableAvatar[index],
                          height: 50,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
              style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(Colors.deepPurple),
                  padding: MaterialStatePropertyAll(EdgeInsets.only(
                      top: 20, bottom: 20, left: 50, right: 50))),
              onPressed: () {
                _saveAvatar();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Select',
                style: TextStyle(color: Colors.white),
              ))
        ],
      ),
    );
  }
}
