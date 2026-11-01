import 'package:equatable/equatable.dart';

import 'errors.dart';

/// Ishod pravila: uspeh sa vrednošću ili greška kao tip (ne kao tekst).
///
/// Tekst poruke za korisnika bira aplikacija, ne domen.
sealed class Result<T> extends Equatable {
  const Result();

  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Failure() => null,
  };

  DomainError? get errorOrNull => switch (this) {
    Success() => null,
    Failure(:final error) => error,
  };

  bool get isSuccess => this is Success<T>;
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  List<Object?> get props => [value];
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}
