import 'package:uuid/uuid.dart';

const uuid = Uuid();

class PasswordCard {
  PasswordCard({
    required this.platformname,
    required this.userid,
    required this.length,
    required this.generatedpassword,
  }) : id = uuid.v4();
  String id;
  String platformname;
  String userid;
  double length;
  // ignore: prefer_typing_uninitialized_variables
  var generatedpassword;
}
