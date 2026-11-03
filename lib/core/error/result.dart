import 'package:posts_clean_bloc/core/error/failures.dart';

/// A minimal functional result type, so the repository can return either a
/// success value or a [Failure] without throwing across layers and without
/// pulling in a heavier dependency like dartz.
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);
  final Failure failure;
}
