import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passgen/data/platformimage.dart';
import 'package:passgen/model/passcard.dart';
import 'package:passgen/provider/savepass_provider.dart';
import 'package:passgen/screen/passeditscreen.dart';

class PasswordList extends ConsumerWidget {
  const PasswordList({super.key, required this.password});
  final List<PasswordCard> password;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, String> platformImages = platformImage;

    return password.isEmpty
        ? Center(
            child: Text(
            'No password added',
            style:
                Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
          ))
        : ListView.builder(
            itemCount: password.length,
            itemBuilder: (context, index) => Card(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        PassEditScreen(passwordCard: password[index]),
                  ));
                },
                child: Dismissible(
                  key: ValueKey(password[index]),
                  background: Container(
                    padding: const EdgeInsets.only(right: 20),
                    alignment: AlignmentDirectional.centerEnd,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color.fromARGB(255, 255, 113, 103)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Delete',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontSize: 15),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.delete),
                      ],
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    final passwordIdToDelete = password[index].id;
                    ref
                        .read(passcardprovider.notifier)
                        .deletePassword(passwordIdToDelete);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      behavior: SnackBarBehavior.floating,
                      dismissDirection: DismissDirection.horizontal,
                      content: const Text('Password Deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          ref
                              .read(passcardprovider.notifier)
                              .generatedPassword(password[index]);
                        },
                      ),
                    ));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                          colors: platformColor[password[index]
                                  .platformname
                                  .trim()
                                  .toLowerCase()] ??
                              const [
                                Color.fromARGB(255, 255, 245, 159),
                                Colors.red
                              ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                    ),
                    child: ListTile(
                      leading: Image.asset(
                        'assets/pImage/${platformImages[password[index].platformname.trim().toLowerCase()] ?? 'unknown.png'}',
                        height: 50,
                      ),
                      title: Text(password[index].platformname),
                      subtitle: Text(password[index].userid),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(
                                  text: password[index].generatedpassword));
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                            },
                            icon: const Icon(Icons.copy),
                          ),
                          // const SizedBox(width: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}
