import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:passgen/screen/tabscreen.dart';

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  LocalAuthentication auth = LocalAuthentication();
  checkAuth() async {
    bool isAvailable;
    isAvailable = await auth.canCheckBiometrics;
    if (isAvailable) {
      bool result =
          await auth.authenticate(localizedReason: 'Unlock to use Fusion');
      if (result) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => TabScreen(),
            ),
            (route) => false);
      } else {}
    } else {}
  }

  @override
  void initState() {
    checkAuth();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.maxFinite,
        width: double.maxFinite,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.10),
            Icon(
              Icons.lock_outline_rounded,
              size: 30,
            ),
            SizedBox(height: 10),
            Text(
              'Fusion Locked',
              style: TextStyle(color: Colors.green, fontSize: 25),
            ),
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.30),
            InkWell(
              onTap: () {
                checkAuth();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Unlock',
                  style: TextStyle(color: Colors.green, fontSize: 20),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
