/// Where a future Fusion backend lives. Fusion is local-only today, so
/// nothing calls it; set with `--dart-define=API_BASE_URL=https://…`.
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment('API_BASE_URL');
  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 20);
  static const sendTimeout = Duration(seconds: 20);
}
