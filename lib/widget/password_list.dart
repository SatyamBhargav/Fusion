import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:passgen/data/platformimage.dart';
import 'package:passgen/model/passcard.dart';

class PasswordList extends StatelessWidget {
  const PasswordList({super.key, required this.password});
  final List<PasswordCard> password;

  @override
  Widget build(BuildContext context) {
    final Map<String, String> platformImages = platformImage;
    if (password.isEmpty) {
      return const Center(
          child: Text(
        'No password added',
      ));
    }
    return ListView.builder(
      itemCount: password.length,
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: Image.asset(
            'assets/pImage/${platformImages[password[index].platformname.toLowerCase()] ?? 'unknown.png'}',
            height: 50,
          ),
          title: Text(password[index].platformname),
          subtitle: Text(password[index].userid),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: password[index].generatedpassword));
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  icon: const Icon(Icons.copy)),
              // const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}
