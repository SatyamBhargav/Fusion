// import 'package:flutter/material.dart';
// import 'package:passgen/data/avatar.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: AvatarSelectionScreen(),
//     );
//   }
// }

// class AvatarSelectionScreen extends StatefulWidget {
//   @override
//   _AvatarSelectionScreenState createState() => _AvatarSelectionScreenState();
// }

// class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
//   List<Color> avatarColors = List.generate(3, (index) => Colors.blue);
//   late int selectedAvatarIndex;

//   void selectAvatar(int index) {
//     setState(() {
//       for (int i = 0; i < avatarColors.length; i++) {
//         avatarColors[i] = i == index ? Colors.green : Colors.blue;
//       }
//       selectedAvatarIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Avatar Selection'),
//       ),
//       body: GridView.builder(
//         itemCount: avatarColors.length,
//         gridDelegate:
//             SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
//         itemBuilder: (context, index) {
//           return InkWell(
//             onTap: () {
//               selectAvatar(index);
//             },
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: CircleAvatar(
//                 backgroundColor: avatarColors[index],
//                 radius: 50,
//                 child: CircleAvatar(
//                   child: availableAvatar[index],
//                   radius: 45,
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passgen/screen/tabscreen.dart';
import 'package:passgen/widget/addavatar.dart';
import 'package:passgen/screen/homescreen.dart';
import 'package:passgen/screen/welcomescreen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const HomeScreen(),
      // home: TabScreen(),
      home: const WelcomeScreen(),
      // home: PassGen(),
      // home: AddAvatar(),
    );
  }
}
