import 'package:equatable/equatable.dart';

/// Which characters a generated password may use, and how long it is.
class GenOptions extends Equatable {
  const GenOptions({
    this.length = 16,
    this.upper = true,
    this.lower = true,
    this.numbers = true,
    this.symbols = true,
  });

  static const minLength = 8;
  static const maxLength = 40;

  final int length;
  final bool upper;
  final bool lower;
  final bool numbers;
  final bool symbols;

  int get enabledCount =>
      [upper, lower, numbers, symbols].where((e) => e).length;

  GenOptions copyWith({
    int? length,
    bool? upper,
    bool? lower,
    bool? numbers,
    bool? symbols,
  }) {
    return GenOptions(
      length: length ?? this.length,
      upper: upper ?? this.upper,
      lower: lower ?? this.lower,
      numbers: numbers ?? this.numbers,
      symbols: symbols ?? this.symbols,
    );
  }

  @override
  List<Object?> get props => [length, upper, lower, numbers, symbols];
}
