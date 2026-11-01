import 'package:equatable/equatable.dart';

/// Stanja termina davanja (glavni pojam sistema).
///
///   Zakazan ──► Potvrđen ──► Pristupio ──► Dao krv
///      │            │            └───────► Odbijen na pregledu
///      ├────────────┴──► Otkazan
///      └────────────┴──► Nije se pojavio
///
/// Svaka podklasa nosi samo podatke koji njoj trebaju.
sealed class AppointmentStatus extends Equatable {
  const AppointmentStatus();

  /// Termin je u toku: davalac ne sme da zakaže novi.
  bool get isActive => switch (this) {
    Scheduled() || Confirmed() || CheckedIn() => true,
    Donated() || Deferred() || Cancelled() || NoShow() => false,
  };

  /// Termin zauzima mesto u slotu.
  bool get occupiesSlot => switch (this) {
    Scheduled() || Confirmed() || CheckedIn() || Donated() || Deferred() => true,
    Cancelled() || NoShow() => false,
  };

  /// Iz ovog stanja nema daljih prelaza.
  bool get isFinal => switch (this) {
    Donated() || Deferred() || Cancelled() || NoShow() => true,
    Scheduled() || Confirmed() || CheckedIn() => false,
  };

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

/// Davalac je zakazao termin.
final class Scheduled extends AppointmentStatus {
  const Scheduled();
}

/// Davalac je potvrdio da dolazi.
final class Confirmed extends AppointmentStatus {
  const Confirmed({required this.at});

  final DateTime at;

  @override
  List<Object?> get props => [at];
}

/// Osoblje je zabeležilo da je davalac stigao na akciju.
final class CheckedIn extends AppointmentStatus {
  const CheckedIn({required this.at});

  final DateTime at;

  @override
  List<Object?> get props => [at];
}

/// Davalac je dao krv.
final class Donated extends AppointmentStatus {
  const Donated({required this.at});

  final DateTime at;

  @override
  List<Object?> get props => [at];
}

/// Davalac je odbijen na lekarskom pregledu.
final class Deferred extends AppointmentStatus {
  const Deferred({required this.at, required this.reason});

  final DateTime at;
  final String reason;

  @override
  List<Object?> get props => [at, reason];
}

/// Termin je otkazan (davalac ili osoblje).
final class Cancelled extends AppointmentStatus {
  const Cancelled({required this.at, required this.byStaff, this.reason = ''});

  final DateTime at;
  final bool byStaff;
  final String reason;

  @override
  List<Object?> get props => [at, byStaff, reason];
}

/// Davalac nije došao na termin.
final class NoShow extends AppointmentStatus {
  const NoShow({required this.at});

  final DateTime at;

  @override
  List<Object?> get props => [at];
}

/// Jedno mesto koje kaže koji su prelazi dozvoljeni.
bool canTransition(AppointmentStatus from, AppointmentStatus to) => switch ((from, to)) {
  (Scheduled(), Confirmed()) => true,
  (Scheduled() || Confirmed(), Cancelled()) => true,
  (Scheduled() || Confirmed(), CheckedIn()) => true,
  (Scheduled() || Confirmed(), NoShow()) => true,
  (CheckedIn(), Donated()) => true,
  (CheckedIn(), Deferred()) => true,
  _ => false,
};
