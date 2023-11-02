import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsernameNotifier extends StateNotifier<String> {
  UsernameNotifier() : super('Name');

  void getUserName(String userDetails) {
    state = userDetails;
  }
}

final userDetailProvider =
    StateNotifierProvider<UsernameNotifier, String>((ref) {
  return UsernameNotifier();
});
