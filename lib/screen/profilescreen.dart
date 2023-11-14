import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passgen/main.dart';
import 'package:passgen/provider/avatarselector_provider.dart';
import 'package:passgen/provider/username_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isTrue = false;
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final userName = ref.watch(userDetailProvider);
    final userAvatar = ref.watch(userprofileprovider);
    // ignore: unused_local_variable
    final userProfileImage = ref.watch(userprofileprovider);
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  child: userAvatar,
                ),
                const SizedBox(height: 20),
                Text(
                  userName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  height: 500,
                  width: 320,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          _isTrue = value;
                          final newThemeMode =
                              value ? ThemeMode.dark : ThemeMode.light;
                          ref.read(themeModeProvider.notifier).state =
                              newThemeMode;
                        },
                        title: Row(
                          children: [
                            _isTrue
                                ? const Icon(
                                    Icons.dark_mode,
                                    size: 30,
                                  )
                                : const Icon(
                                    Icons.light_mode,
                                    size: 30,
                                  ),
                            const SizedBox(width: 15),
                            Text(
                              'Dark Mode',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Text(
                  'Version 1.0.0',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontSize: 15),
                ),
                SizedBox(height: 10),
                Text(
                  'Designed by SB',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontSize: 15),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
