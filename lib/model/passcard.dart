import 'package:uuid/uuid.dart';

const uuid = Uuid();

class PasswordCard {
  PasswordCard(
      {required this.addTime,
      required this.platformname,
      required this.userid,
      required this.length,
      required this.generatedpassword,
      String? id})
      : id = id ?? uuid.v4();
  String id;
  String platformname;
  String userid;
  num length;
  // ignore: prefer_typing_uninitialized_variables
  String generatedpassword;
  DateTime addTime;
}
