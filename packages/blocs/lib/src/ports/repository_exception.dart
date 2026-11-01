/// Greška u pristupu podacima: nema mreže, server ne odgovara i slično.
/// Nije pravilo domena, pa nije DomainError.
final class RepositoryException implements Exception {
  const RepositoryException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'RepositoryException: $message';
}
