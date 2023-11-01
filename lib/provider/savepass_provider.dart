import 'package:passgen/model/passcard.dart';
import 'package:riverpod/riverpod.dart';

class SavePasswordNotifier extends StateNotifier<List<PasswordCard>> {
  SavePasswordNotifier() : super([]);

  void generatedPassword(PasswordCard passcard) {
    // ignore: unused_local_variable
    final passIsAdded = state.contains(passcard);

    state = [passcard, ...state];
  }
}

final passcardprovider =
    StateNotifierProvider<SavePasswordNotifier, List<PasswordCard>>((ref) {
  return SavePasswordNotifier();
});
