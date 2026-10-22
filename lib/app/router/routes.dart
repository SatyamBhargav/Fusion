/// Every location in the app. Only ids go in a path: objects and secrets
/// never travel through the router.
abstract final class Routes {
  // Picked by the app from the account and lock state.
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const lock = '/lock';
  static const setup = '/setup';
  static const home = '/home';

  // Opened on top.
  static const signUp = '/signup';
  static const forgot = '/forgot';
  static const reset = '/reset';
  static const newItem = '/item/new';
  static String item(String id) => '/item/$id';
  static String editItem(String id) => '/item/$id/edit';

  /// The generator in pick mode; pops with the chosen password.
  static const pickPassword = '/generate/pick';
  static const changePin = '/settings/pin';
}
