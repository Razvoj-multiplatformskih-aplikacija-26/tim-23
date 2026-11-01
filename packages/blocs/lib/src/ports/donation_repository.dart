import 'package:domain/domain.dart';

/// Port: jedino mesto kroz koje Bloc-ovi dolaze do podataka.
///
/// U KT1 ga implementira lažni repozitorijum u memoriji (u svakoj aplikaciji),
/// a od KT2 HTTP adapter ka serveru. Bloc-ovi i ekrani se tada ne menjaju.
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

  /// Čuva termin u novom stanju.
  Future<Appointment> saveAppointment(Appointment appointment);

  Future<Donor> saveDonor(Donor donor);
}
