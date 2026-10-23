import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/effects.dart';
import '../../domain/entities/gen_options.dart';
import '../../domain/usecases/generate_password.dart';

class GeneratorState extends Equatable {
  const GeneratorState({
    required this.options,
    required this.password,
    this.copied = false,
  });

  final GenOptions options;
  final String password;

  /// Shows "Copied" for a moment after copying.
  final bool copied;

  @override
  List<Object?> get props => [options, password, copied];
}

enum GeneratorEffect {
  /// Turning off the last character type was refused.
  keepOneType,
}

enum CharacterSet { upper, lower, numbers, symbols }

class GeneratorCubit extends Cubit<GeneratorState>
    with Effects<GeneratorState, GeneratorEffect> {
  GeneratorCubit({required GeneratePassword generatePassword})
    : _generate = generatePassword,
      super(
        GeneratorState(
          options: const GenOptions(),
          password: generatePassword(const GenOptions()),
        ),
      );

  final GeneratePassword _generate;
  Timer? _copiedTimer;

  void _regenerate(GenOptions options) =>
      emit(GeneratorState(options: options, password: _generate(options)));

  void regenerate() => _regenerate(state.options);

  void setLength(int length) {
    if (length == state.options.length) return;
    _regenerate(state.options.copyWith(length: length));
  }

  /// Returns false (and says why) when it would leave no character type.
  bool toggle(CharacterSet set) {
    final o = state.options;
    final next = switch (set) {
      CharacterSet.upper => o.copyWith(upper: !o.upper),
      CharacterSet.lower => o.copyWith(lower: !o.lower),
      CharacterSet.numbers => o.copyWith(numbers: !o.numbers),
      CharacterSet.symbols => o.copyWith(symbols: !o.symbols),
    };
    if (next.enabledCount == 0) {
      effect(GeneratorEffect.keepOneType);
      return false;
    }
    _regenerate(next);
    return true;
  }

  /// Call after putting the password on the clipboard.
  void copied() {
    emit(
      GeneratorState(
        options: state.options,
        password: state.password,
        copied: true,
      ),
    );
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(milliseconds: 1600), () {
      emit(GeneratorState(options: state.options, password: state.password));
    });
  }

  @override
  Future<void> close() {
    _copiedTimer?.cancel();
    return super.close();
  }
}
