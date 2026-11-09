import 'package:domain/domain.dart';

/// Port: jedino mesto kroz koje Bloc-ovi dolaze do podataka.
///
/// Implementiraju ga lažni repozitorijum u memoriji (demo i testovi) i
/// HttpDonationRepository iz paketa api_client (server). Bloc-ovi i ekrani
/// ne znaju koja je implementacija izabrana.
/// Svaka metoda može da baci [RepositoryException].
abstract interface class DonationRepository {
  /// Sve akcije, poređane po početku.
  Future<List<DonationDrive>> drives();

  Future<DonationDrive?> drive(DriveId id);

  Future<Donor?> donor(DonorId id);

  Future<List<Donor>> donors();

  Future<List<Appointment>> appointmentsOfDonor(DonorId id);

  Future<List<Appointment>> appointmentsOfDrive(DriveId id);

  /// Zakazuje termin. Pravila ponovo proverava druga strana (od KT2 server),
  /// jer kapacitet zavisi od termina drugih davalaca.
  Future<Result<Appointment>> book({required DonorId donorId, required DriveId driveId, required DateTime slotStart});

  /// Čuva termin u novom stanju. Druga strana (od KT2 server) ponovo
  /// proverava pravila i može da odbije, npr. ako je termin u međuvremenu promenjen.
  Future<Result<Appointment>> saveAppointment(Appointment appointment);

  /// Čuva profil davaoca; server ponovo proverava pravila profila.
  Future<Result<Donor>> saveDonor(Donor donor);
}
