import 'package:api_contract/api_contract.dart' show dayFromJson, dayToJson;
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

/// Postgres kôd greške za prekršen jedinstveni indeks.
const uniqueViolation = '23505';

/// Indeks koji čuva pravilo „najviše jedan aktivan termin“.
const oneActivePerDonor = 'appointments_one_active_per_donor';

const _appointmentColumns = '''
  id::text, donor_id, drive_id, slot_start, slot_minutes, status, status_at, status_reason, by_staff
''';

const _donorColumns = '''
  d.id, u.name, to_char(d.birth_date, 'YYYY-MM-DD'), d.sex, d.blood_group, d.city,
  to_char(d.last_donation, 'YYYY-MM-DD')
''';

/// SQL na jednom mestu. Radi i nad celom bazom (Pool) i unutar transakcije.
final class KapStore {
  const KapStore(this._database);

  final Session _database;

  Future<bool> isEmpty() async {
    final rows = await _database.execute('SELECT count(*) FROM users');
    return rows.single[0] == 0;
  }

  // Akcije.

  Future<List<DonationDrive>> drives() async {
    final rows = await _database.execute(
      'SELECT id, title, city, address, starts_at, ends_at, slot_minutes, slot_capacity FROM drives ORDER BY starts_at',
    );
    return [for (final row in rows) _drive(row)];
  }

  Future<DonationDrive?> drive(DriveId id) async {
    final rows = await _database.execute(
      Sql.named(
        'SELECT id, title, city, address, starts_at, ends_at, slot_minutes, slot_capacity FROM drives WHERE id = @id',
      ),
      parameters: {'id': id.value},
    );
    return rows.isEmpty ? null : _drive(rows.single);
  }

  /// Zaključava akciju do kraja transakcije. Dva istovremena zakazivanja na istoj akciji
  /// tako idu jedno za drugim, pa drugo vidi termin prvog i pravilo kapaciteta važi.
  Future<bool> lockDrive(DriveId id) async {
    final rows = await _database.execute(
      Sql.named('SELECT id FROM drives WHERE id = @id FOR UPDATE'),
      parameters: {'id': id.value},
    );
    return rows.isNotEmpty;
  }

  Future<void> insertDrive(DonationDrive drive) async {
    await _database.execute(
      Sql.named('''
        INSERT INTO drives (id, title, city, address, starts_at, ends_at, slot_minutes, slot_capacity)
        VALUES (@id, @title, @city, @address, @starts, @ends, @minutes, @capacity)
      '''),
      parameters: {
        'id': drive.id.value,
        'title': drive.title,
        'city': drive.city,
        'address': drive.address,
        'starts': drive.start.toUtc(),
        'ends': drive.end.toUtc(),
        'minutes': drive.slotLength.inMinutes,
        'capacity': drive.slotCapacity,
      },
    );
  }

  // Nalozi i davaoci.

  Future<void> insertUser(User user, {String? login, String? passwordHash}) async {
    await _database.execute(
      Sql.named('INSERT INTO users (id, name, role, login, password_hash) VALUES (@id, @name, @role, @login, @hash)'),
      parameters: {'id': user.id.value, 'name': user.name, 'role': user.role.name, 'login': login, 'hash': passwordHash},
    );
  }

  Future<void> insertDonor(Donor donor) async {
    await _database.execute(
      Sql.named('''
        INSERT INTO donors (id, birth_date, sex, blood_group, city, last_donation)
        VALUES (@id, @birth::date, @sex, @group, @city, @last::date)
      '''),
      parameters: _donorParameters(donor),
    );
  }

  Future<List<Donor>> donors() async {
    final rows = await _database.execute('SELECT $_donorColumns FROM donors d JOIN users u ON u.id = d.id ORDER BY u.name');
    return [for (final row in rows) _donor(row)];
  }

  Future<Donor?> donor(DonorId id) async {
    final rows = await _database.execute(
      Sql.named('SELECT $_donorColumns FROM donors d JOIN users u ON u.id = d.id WHERE d.id = @id'),
      parameters: {'id': id.value},
    );
    return rows.isEmpty ? null : _donor(rows.single);
  }

  /// Čuva profil: ime je u nalogu, ostalo u zapisu davaoca.
  Future<void> saveDonor(Donor donor) async {
    await _database.execute(
      Sql.named('UPDATE users SET name = @name WHERE id = @id'),
      parameters: {'id': donor.id.value, 'name': donor.name.value},
    );
    await _database.execute(
      Sql.named('''
        UPDATE donors SET birth_date = @birth::date, sex = @sex, blood_group = @group, city = @city,
          last_donation = @last::date
        WHERE id = @id
      '''),
      parameters: _donorParameters(donor),
    );
  }

  // Termini.

  Future<List<Appointment>> appointmentsOfDrive(DriveId id) =>
      _appointments('drive_id = @id', {'id': id.value});

  Future<List<Appointment>> appointmentsOfDonor(DonorId id) =>
      _appointments('donor_id = @id', {'id': id.value});

  Future<Appointment?> appointment(AppointmentId id) async {
    if (!_uuid.hasMatch(id.value)) return null;
    final found = await _appointments('id = @id::uuid', {'id': id.value});
    return found.isEmpty ? null : found.single;
  }

  /// Upisuje novi termin; id daje baza.
  Future<Appointment> insertAppointment(Appointment appointment) async {
    final columns = _statusColumns(appointment.status);
    final rows = await _database.execute(
      Sql.named('''
        INSERT INTO appointments (donor_id, drive_id, slot_start, slot_minutes, status, status_at, status_reason, by_staff)
        VALUES (@donor, @drive, @start, @minutes, @status, @at, @reason, @byStaff)
        RETURNING id::text
      '''),
      parameters: {
        'donor': appointment.donorId.value,
        'drive': appointment.driveId.value,
        'start': appointment.slotStart.toUtc(),
        'minutes': appointment.slotLength.inMinutes,
        ...columns,
      },
    );
    return Appointment(
      id: AppointmentId(rows.single[0]! as String),
      donorId: appointment.donorId,
      driveId: appointment.driveId,
      slotStart: appointment.slotStart,
      slotLength: appointment.slotLength,
      status: appointment.status,
    );
  }

  /// Menja stanje samo ako je termin i dalje u stanju [from]. Ako ga je u međuvremenu
  /// promenio neko drugi (drugi klijent), ništa se ne menja i vraća se false.
  Future<bool> changeStatus(Appointment changed, {required AppointmentStatus from}) async {
    final result = await _database.execute(
      Sql.named('''
        UPDATE appointments
        SET status = @status, status_at = @at, status_reason = @reason, by_staff = @byStaff
        WHERE id = @id::uuid AND status = @previous
      '''),
      parameters: {'id': changed.id.value, 'previous': from.kind, ..._statusColumns(changed.status)},
    );
    if (result.affectedRows != 1) return false;
    // Posle davanja menja se i datum poslednjeg davanja davaoca.
    if (changed.status case Donated(:final at)) {
      await _database.execute(
        Sql.named('UPDATE donors SET last_donation = @day::date WHERE id = @id'),
        parameters: {'id': changed.donorId.value, 'day': dayToJson(at)},
      );
    }
    return true;
  }

  Future<List<Appointment>> _appointments(String where, Map<String, Object?> parameters) async {
    final rows = await _database.execute(
      Sql.named('SELECT $_appointmentColumns FROM appointments WHERE $where ORDER BY slot_start'),
      parameters: parameters,
    );
    return [for (final row in rows) _appointment(row.toColumnMap())];
  }
}

final _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

Map<String, Object?> _donorParameters(Donor donor) => {
  'id': donor.id.value,
  'birth': dayToJson(donor.birthDate),
  'sex': donor.sex.name,
  'group': donor.bloodGroup.name,
  'city': donor.city,
  'last': donor.lastDonation == null ? null : dayToJson(donor.lastDonation!),
};

DonationDrive _drive(ResultRow row) => DonationDrive(
  id: DriveId(row[0]! as String),
  title: row[1]! as String,
  city: row[2]! as String,
  address: row[3]! as String,
  start: (row[4]! as DateTime).toUtc(),
  end: (row[5]! as DateTime).toUtc(),
  slotLength: Duration(minutes: row[6]! as int),
  slotCapacity: row[7]! as int,
);

Donor _donor(ResultRow row) => Donor(
  id: DonorId(row[0]! as String),
  name: DonorName.parse(row[1]! as String).valueOrNull!,
  birthDate: dayFromJson(row[2]! as String),
  sex: sexFromJson(row[3]! as String),
  bloodGroup: bloodGroupFromJson(row[4]! as String),
  city: row[5]! as String,
  lastDonation: switch (row[6]) {
    final String day => dayFromJson(day),
    _ => null,
  },
);

Appointment _appointment(Map<String, dynamic> row) {
  final at = (row['status_at'] as DateTime?)?.toUtc();
  final reason = row['status_reason'] as String? ?? '';
  return Appointment(
    id: AppointmentId(row['id'] as String),
    donorId: DonorId(row['donor_id'] as String),
    driveId: DriveId(row['drive_id'] as String),
    slotStart: (row['slot_start'] as DateTime).toUtc(),
    slotLength: Duration(minutes: row['slot_minutes'] as int),
    status: switch (row['status']) {
      'confirmed' => Confirmed(at: at!),
      'checked-in' => CheckedIn(at: at!),
      'donated' => Donated(at: at!),
      'deferred' => Deferred(at: at!, reason: reason),
      'cancelled' => Cancelled(at: at!, byStaff: row['by_staff'] as bool? ?? false, reason: reason),
      'no-show' => NoShow(at: at!),
      _ => const Scheduled(),
    },
  );
}

/// Kolone stanja; vrsta stanja je ista reč kao na mreži (AppointmentStatusDto).
Map<String, Object?> _statusColumns(AppointmentStatus status) => {
  'status': status.kind,
  'at': switch (status) {
    Scheduled() => null,
    Confirmed(:final at) || CheckedIn(:final at) || Donated(:final at) || NoShow(:final at) => at.toUtc(),
    Deferred(:final at) || Cancelled(:final at) => at.toUtc(),
  },
  'reason': switch (status) {
    Deferred(:final reason) || Cancelled(:final reason) => reason,
    _ => null,
  },
  'byStaff': switch (status) {
    Cancelled(:final byStaff) => byStaff,
    _ => null,
  },
};
