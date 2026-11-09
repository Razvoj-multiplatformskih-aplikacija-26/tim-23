/// Zašto podaci nisu stigli. Ekran po tome bira poruku.
enum RepositoryFailure {
  /// Opšta greška (npr. lažni repozitorijum u demo režimu).
  unavailable,

  /// Server ne odgovara ili nema mreže.
  unreachable,

  /// Server je vratio grešku ili odgovor koji ne može da se pročita.
  serverError,

  /// Server je odbio zahtev kodom koji ova verzija aplikacije ne poznaje.
  refused,

  /// Prijava je istekla ili ne postoji.
  sessionExpired,
}

/// Greška u pristupu podacima. Nije pravilo domena, pa nije DomainError.
final class RepositoryException implements Exception {
  const RepositoryException(this.message, {this.failure = RepositoryFailure.unavailable, this.cause});

  final String message;
  final RepositoryFailure failure;
  final Object? cause;

  @override
  String toString() => 'RepositoryException(${failure.name}): $message';
}
