import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generator/domain/entities/gen_options.dart';
import '../../../generator/domain/usecases/generate_password.dart';

/// The demo password on the welcome screen, re-rolled every few seconds.
class WelcomeCubit extends Cubit<String> {
  WelcomeCubit({required GeneratePassword generatePassword})
    : super(r'k7#Qm!9vRz&2') {
    _timer = Timer.periodic(const Duration(milliseconds: 2800), (_) {
      emit(generatePassword(const GenOptions(length: 12)));
    });
  }

  late final Timer _timer;

  @override
  Future<void> close() {
    _timer.cancel();
    return super.close();
  }
}
