import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserAvatarNotifier extends StateNotifier<Image> {
  UserAvatarNotifier()
      : super(Image.asset(
          'assets/images/default.png',
          height: 60,
        ));

  void getUserAvatar(Image userAvatar) {
    state = userAvatar;
  }
}

final userprofileprovider =
    StateNotifierProvider<UserAvatarNotifier, Image>((ref) {
  return UserAvatarNotifier();
});
