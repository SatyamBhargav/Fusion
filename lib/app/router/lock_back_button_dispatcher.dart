import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Swallows the system back button while the app lock covers the screen,
/// so it can't pop the page hidden underneath.
class LockBackButtonDispatcher extends RootBackButtonDispatcher {
  LockBackButtonDispatcher(this._locked);

  final bool Function() _locked;

  @override
  Future<bool> invokeCallback(Future<bool> defaultValue) {
    if (_locked()) return SynchronousFuture(true);
    return super.invokeCallback(defaultValue);
  }
}
