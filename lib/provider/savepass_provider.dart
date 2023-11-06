import 'package:passgen/model/passcard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SavePasswordNotifier extends StateNotifier<List<PasswordCard>> {
  SavePasswordNotifier() : super([]);

  void generatedPassword(PasswordCard passcard) {
    // ignore: unused_local_variable
    final passIsAdded = state.contains(passcard);

    state = [passcard, ...state];
  }

  void filtername(String pName) {
    List<PasswordCard> result = [];
    if (pName.isEmpty) {
      result = state;
    } else {
      result = state
          .where((element) => element.platformname
              .toString()
              .toLowerCase()
              .contains(pName.toLowerCase()))
          .toList();
    }
    state = result;
  }
}

final passcardprovider =
    StateNotifierProvider<SavePasswordNotifier, List<PasswordCard>>((ref) {
  return SavePasswordNotifier();
});
