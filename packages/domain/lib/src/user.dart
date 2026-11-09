import 'package:equatable/equatable.dart';

import 'identifiers.dart';

/// Uloge u sistemu. Davalac koristi mobilnu aplikaciju, a medicinska
/// sestra i koordinator backoffice.
enum Role {
  donor,
  nurse,
  coordinator;

  bool get isStaff => this != Role.donor;
}

/// Prijavljeni korisnik. Server ga zna samo iz prijave koju je sam izdao.
final class User extends Equatable {
  const User({required this.id, required this.name, required this.role});

  final UserId id;
  final String name;
  final Role role;

  /// Davalac je i nalog i zapis davaoca, sa istim id-jem.
  DonorId get donorId => DonorId(id.value);

  @override
  List<Object?> get props => [id, name, role];

  @override
  String toString() => 'User($name, ${role.name})';
}
