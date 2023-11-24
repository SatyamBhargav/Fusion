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
        // mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 30),
          Text(
            'Select Avatar',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.builder(
              itemCount: avatarColors.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    selectAvatar(index);
                    _saveAvatar();
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 29),
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
        ],
      ),
    );
  }
}
