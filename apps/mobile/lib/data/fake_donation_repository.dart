import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

import 'seed.dart';

/// Lažna implementacija porta: podaci žive u memoriji aplikacije.
///
/// Svaki zahtev čeka [latency] (da se vidi učitavanje). [failingRequests]
/// i [emptyResponses] su brojači za demo: sledeći zahtev ne uspe, odnosno
/// sledeća lista stigne prazna. Od KT2 ovu klasu zamenjuje HTTP adapter.
final class FakeDonationRepository implements DonationRepository {
  FakeDonationRepository({required this.clock, this.latency = const Duration(milliseconds: 300)}) {
    final seed = Seed(clock());
    _drives.addAll(seed.drives);
    _donors.addAll(seed.donors);
    _appointments.addAll(seed.appointments);
  }

  final Clock clock;
  final Duration latency;

  final _drives = <DonationDrive>[];
  final _donors = <Donor>[];
  final _appointments = <Appointment>[];
  var _nextId = 1;

  /// Koliko sledećih zahteva treba da ne uspe.
  int failingRequests = 0;

  /// Koliko sledećih listi treba da stigne prazno.
  int emptyResponses = 0;

  Future<void> _roundTrip() async {
    await Future<void>.delayed(latency);
    if (failingRequests > 0) {
      failingRequests--;
      throw const RepositoryException('Simuliran prekid veze');
    }
  }

  bool _answersEmpty() {
    if (emptyResponses == 0) return false;
    emptyResponses--;
    return true;
  }

  @override
  Future<List<DonationDrive>> drives() async {
    await _roundTrip();
    if (_answersEmpty()) return const [];
    return [..._drives]..sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  Future<DonationDrive?> drive(DriveId id) async {
    await _roundTrip();
    return _drives.where((d) => d.id == id).firstOrNull;
  }

  @override
  Future<Donor?> donor(DonorId id) async {
    await _roundTrip();
    return _donors.where((d) => d.id == id).firstOrNull;
  }

  @override
  Future<List<Donor>> donors() async {
    await _roundTrip();
    return List.of(_donors);
  }

  @override
  Future<List<Appointment>> appointmentsOfDonor(DonorId id) async {
    await _roundTrip();
    if (_answersEmpty()) return const [];
    return _appointments.where((a) => a.donorId == id).toList();
  }

  @override
  Future<List<Appointment>> appointmentsOfDrive(DriveId id) async {
    await _roundTrip();
    if (_answersEmpty()) return const [];
    return _appointments.where((a) => a.driveId == id).toList();
  }

  /// Radi isto što će raditi server: ponovo proverava sva pravila nad
  /// svim terminima, pa tek onda čuva.
  @override
  Future<Result<Appointment>> book({
    required DonorId donorId,
    required DriveId driveId,
    required DateTime slotStart,
  }) async {
    await _roundTrip();
    final donor = _donors.where((d) => d.id == donorId).firstOrNull;
    final drive = _drives.where((d) => d.id == driveId).firstOrNull;
    if (donor == null || drive == null) return const Failure(NotFound());
    final result = bookAppointment(
      id: AppointmentId('a-novi-${_nextId++}'),
      donor: donor,
      drive: drive,
      slotStart: slotStart,
      donorAppointments: _appointments.where((a) => a.donorId == donorId).toList(),
      driveAppointments: _appointments.where((a) => a.driveId == driveId).toList(),
      now: clock(),
    );
    if (result case Success(:final value)) _appointments.add(value);
    return result;
  }

  @override
  Future<Appointment> saveAppointment(Appointment appointment) async {
    await _roundTrip();
    final index = _appointments.indexWhere((a) => a.id == appointment.id);
    if (index < 0) throw const RepositoryException('Termin ne postoji');
    _appointments[index] = appointment;
    // Posle davanja menja se i datum poslednjeg davanja davaoca.
    if (appointment.status case Donated(:final at)) {
      final donorIndex = _donors.indexWhere((d) => d.id == appointment.donorId);
      if (donorIndex >= 0) _donors[donorIndex] = _donors[donorIndex].copyWith(lastDonation: at);
    }
    return appointment;
  }

  @override
  Future<Donor> saveDonor(Donor donor) async {
    await _roundTrip();
    final index = _donors.indexWhere((d) => d.id == donor.id);
    if (index < 0) throw const RepositoryException('Davalac ne postoji');
    _donors[index] = donor;
    return donor;
  }
}
