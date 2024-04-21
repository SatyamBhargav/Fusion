import 'dart:developer';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passgen/provider/avatarselector_provider.dart';
import 'package:passgen/provider/savepass_provider.dart';
import 'package:passgen/provider/theme_provider.dart';
import 'package:passgen/provider/username_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    // final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;
    final userName = ref.watch(userDetailProvider);
    final userAvatar = ref.watch(userprofileprovider);
    // bool _isTrue = ref.watch(themeProvider);
    String? filePath;
    Future<void> pickFile(context) async {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          filePath = result.files.single.path!;
        });
      }
      ref.read(passcardprovider.notifier).uploadData(filePath!, context);
    }

    // ignore: unused_local_variable
    final userProfileImage = ref.watch(userprofileprovider);
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
            child: Column(
              children: [
                Image.asset(
                  userAvatar,
                  height: 90,
                ),
                const SizedBox(height: 20),
                Text(
                  userName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 50),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Tooltip(
                            message: 'Download Your Passwords',
                            waitDuration: Duration(milliseconds: 0),
                            child: Icon(
                              Icons.info_rounded,
                              size: 30,
                            ),
                          ),
                          title: Text(
                            'Download',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          trailing: IconButton(
                              onPressed: () {
                                ref.read(passcardprovider.notifier).printData();
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        dismissDirection:
                                            DismissDirection.horizontal,
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                            'Password Saved to Download Folder')));
                              },
                              icon: const Icon(
                                Icons.download,
                                size: 30,
                              )),
                        ),
                        ListTile(
                          leading: const Tooltip(
                            message: 'Download Your Passwords',
                            waitDuration: Duration(milliseconds: 0),
                            child: Icon(
                              Icons.info_rounded,
                              size: 30,
                            ),
                          ),
                          title: Text(
                            'Upload',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          trailing: IconButton(
                              onPressed: () {
                                pickFile(context);
                              },
                              icon: const Icon(
                                Icons.file_upload_outlined,
                                size: 30,
                              )),
                        ),
                        const SizedBox(height: 20),
                        Consumer(
                          builder: (context, ref, child) {
                            final isTrue = ref.watch(themeProvider);
                            return SwitchListTile(
                              value: isTrue,
                              onChanged: (value) {
                                ref
                                    .read(themeProvider.notifier)
                                    .setTheme(value);
                              },
                              title: Row(
                                children: [
                                  isTrue
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
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // const SizedBox(height: 20),
                        // Text(
                        //     MediaQuery.of(context).size.height.toStringAsFixed(2),
                        //     style: Theme.of(context).textTheme.titleMedium),
                        // const SizedBox(height: 20),
                        // Text(MediaQuery.of(context).size.width.toStringAsFixed(2),
                        //     style: Theme.of(context).textTheme.titleMedium)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
