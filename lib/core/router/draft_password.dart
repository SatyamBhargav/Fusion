/// Hands a generated password to the new-login form without putting it in
/// the route (route state can be reported to the platform). Read once.
class DraftPassword {
  String? _value;

  void set(String password) => _value = password;

  String? take() {
    final v = _value;
    _value = null;
    return v;
  }
}
