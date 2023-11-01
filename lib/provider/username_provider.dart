import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsernameNotifier extends StateNotifier<String> {
  UsernameNotifier() : super('');

  void getUserName(String userDetails) {
    state = userDetails;
  }

  void getUserAvatar(Image userAvatar) {
    state = userAvatar.toString();
  }
}

final userDetailProvider =
    StateNotifierProvider<UsernameNotifier, String>((ref) {
  return UsernameNotifier();
});
