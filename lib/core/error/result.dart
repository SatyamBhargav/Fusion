import 'failures.dart';

/// The outcome of a use case: a value, or a [Failure] to show.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  Failure? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}

const ok = Ok<void>(null);
