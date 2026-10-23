/// One thing the app can do. [T] is often a `Future`.
abstract interface class UseCase<T, P> {
  T call(P params);
}

/// For use cases that take nothing.
final class NoParams {
  const NoParams();
}
