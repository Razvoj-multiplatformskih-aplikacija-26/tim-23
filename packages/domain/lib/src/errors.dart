import 'package:equatable/equatable.dart';

import 'appointment/appointment_status.dart';

/// Sve greške koje pravila mogu da vrate.
///
/// sealed znači da kompajler zna svaku podklasu, pa switch u aplikaciji
/// (gde se bira tekst poruke) mora da pokrije svaku grešku.
sealed class DomainError extends Equatable {
  const DomainError();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

/// Ime i prezime nije između [min] i [max] znakova.
final class InvalidDonorName extends DomainError {
  const InvalidDonorName({required this.length, required this.min, required this.max});

  final int length;
  final int min;
  final int max;

  @override
  List<Object?> get props => [length, min, max];
}

/// Davalac na dan davanja nema između [min] i [max] godina.
final class AgeOutOfRange extends DomainError {
  const AgeOutOfRange({required this.age, required this.min, required this.max});

  final int age;
  final int min;
  final int max;

  @override
  List<Object?> get props => [age, min, max];
}

/// Datum poslednjeg davanja je u budućnosti.
final class LastDonationInFuture extends DomainError {
  const LastDonationInFuture();
}

/// Nije prošlo dovoljno vremena od poslednjeg davanja.
final class TooSoonToDonate extends DomainError {
  const TooSoonToDonate(this.nextAllowed);

  /// Prvi dan kada davalac ponovo sme da da krv.
  final DateTime nextAllowed;

  @override
  List<Object?> get props => [nextAllowed];
}

/// Davalac već ima aktivan termin.
final class ActiveAppointmentExists extends DomainError {
  const ActiveAppointmentExists();
}

/// U izabranom slotu nema slobodnih mesta.
final class SlotFull extends DomainError {
  const SlotFull();
}

/// Slot je već počeo ili je prošao.
final class SlotInPast extends DomainError {
  const SlotInPast();
}

/// Izabrano vreme nije slot ove akcije.
final class SlotNotInDrive extends DomainError {
  const SlotNotInDrive();
}

/// Davalac otkazuje kasnije od dozvoljenog roka.
final class CancellationTooLate extends DomainError {
  const CancellationTooLate(this.deadline);

  /// Poslednji trenutak kada je otkazivanje bilo dozvoljeno.
  final DateTime deadline;

  @override
  List<Object?> get props => [deadline];
}

/// Termin je već počeo, pa se više ne može potvrditi ni otkazati.
final class AppointmentStarted extends DomainError {
  const AppointmentStarted();
}

/// Dolazak se beleži samo u vremenu oko termina.
final class CheckInOutsideWindow extends DomainError {
  const CheckInOutsideWindow();
}

/// „Nije se pojavio“ može tek kada termin počne.
final class AppointmentNotStarted extends DomainError {
  const AppointmentNotStarted();
}

/// Razlog odbijanja na pregledu nije između [min] i [max] znakova.
final class InvalidDeferralReason extends DomainError {
  const InvalidDeferralReason({required this.length, required this.min, required this.max});

  final int length;
  final int min;
  final int max;

  @override
  List<Object?> get props => [length, min, max];
}

/// Prelaz iz stanja [from] u stanje [to] nije dozvoljen.
final class InvalidTransition extends DomainError {
  const InvalidTransition({required this.from, required this.to});

  final AppointmentStatus from;
  final AppointmentStatus to;

  @override
  List<Object?> get props => [from.runtimeType, to.runtimeType];

  @override
  String toString() => 'InvalidTransition(${from.runtimeType} -> ${to.runtimeType})';
}

/// Traženi zapis ne postoji (ili korisnik nema pravo da ga vidi).
final class NotFound extends DomainError {
  const NotFound();
}

/// Korisnik nema pravo na ovu akciju.
final class NotAllowed extends DomainError {
  const NotAllowed();
}
