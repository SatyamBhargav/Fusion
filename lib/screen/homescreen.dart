import 'package:flutter/material.dart';
import 'package:passgen/provider/avatarselector_provider.dart';
import 'package:passgen/provider/savepass_provider.dart';
import 'package:passgen/provider/username_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passgen/widget/password_list.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Future<void> _userFuture;
  @override
  void initState() {
    super.initState();
    _userFuture = ref.read(passcardprovider.notifier).loaddetails();
  }

  @override
  Widget build(BuildContext context) {
    final passwordInfo = ref.watch(passcardprovider);
    final userNameDetail = ref.watch(userDetailProvider);
    final userAvatarDetail = ref.watch(userprofileprovider);

    return SafeArea(
      child: Scaffold(
        // backgroundColor: const Color.fromARGB(234, 255, 255, 255),
        body: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                children: [
                  Text(
                    'Hello, $userNameDetail',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 35,
                    child: userAvatarDetail,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) =>
                          ref.read(passcardprovider.notifier).filtername(value),
                      decoration: const InputDecoration(
                          hintText: 'Search',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)))),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Saved Password',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 35),
                  child: FutureBuilder(
                      future: _userFuture,
                      builder: (context, snapshot) =>
                          snapshot.connectionState == ConnectionState.waiting
                              ? const Center(child: CircularProgressIndicator())
                              : PasswordList(password: passwordInfo))),
            ),
          ],
        ),
      ),
    );
  }
}
