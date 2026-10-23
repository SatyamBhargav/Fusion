import 'package:equatable/equatable.dart';

/// The one local account on this device.
class Account extends Equatable {
  const Account({this.name, this.email});

  final String? name;
  final String? email;

  String get firstName {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '';
    return n.split(RegExp(r'\s+')).first;
  }

  @override
  List<Object?> get props => [name, email];
}
