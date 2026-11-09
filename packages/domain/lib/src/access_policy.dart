import 'appointment/appointment.dart';
import 'appointment/appointment_rules.dart';
import 'identifiers.dart';
import 'user.dart';

/// Sva prava na jednom mestu. Koriste ih i klijenti (šta da prikažu)
/// i server (šta da dozvoli), pa ne mogu da se razlikuju.
abstract final class AccessPolicy {
  /// Mobilna aplikacija je za davaoce.
  static bool canUseMobileApp(User user) => user.role == Role.donor;

  /// Backoffice je za osoblje.
  static bool canUseBackoffice(User user) => user.role.isStaff;

  /// Termin pripada davaocu koji je prijavljen.
  static bool owns(User user, Appointment appointment) => appointment.donorId.value == user.id.value;

  /// Davalac vidi samo svoj profil i svoje termine; osoblje vidi sve.
  static bool canViewDonor(User user, DonorId donorId) => user.role.isStaff || donorId.value == user.id.value;

  /// Spisak svih davalaca vidi samo osoblje.
  static bool canViewAllDonors(User user) => user.role.isStaff;

  /// Ko je zakazao koji termin vidi osoblje, a davalac samo za svoje termine.
  static bool canSeeWhoBooked(User user, Appointment appointment) => user.role.isStaff || owns(user, appointment);

  /// Profil menja samo davalac, i to samo svoj.
  static bool canEditProfile(User user, DonorId donorId) => user.role == Role.donor && donorId.value == user.id.value;

  /// Termin zakazuje davalac, za sebe.
  static bool canBook(User user) => user.role == Role.donor;

  /// Dolazak potvrđuje davalac, samo za svoj termin.
  static bool canConfirm(User user, Appointment appointment) => user.role == Role.donor && owns(user, appointment);

  /// Otkazuje davalac svoj termin (uz rok od 12 sati) ili koordinator bilo koji.
  static bool canCancel(User user, Appointment appointment) => switch (user.role) {
    Role.donor => owns(user, appointment),
    Role.coordinator => true,
    Role.nurse => false,
  };

  /// Akcije u backoffice-u: ishod pregleda beleži osoblje, a otkazuje koordinator.
  static bool canPerform(User user, StaffAction action) => switch (action) {
    StaffAction.cancel => user.role == Role.coordinator,
    StaffAction.checkIn || StaffAction.donated || StaffAction.deferred || StaffAction.noShow => user.role.isStaff,
  };
}
