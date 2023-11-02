import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passgen/provider/avatarselector_provider.dart';
import 'package:passgen/provider/username_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
