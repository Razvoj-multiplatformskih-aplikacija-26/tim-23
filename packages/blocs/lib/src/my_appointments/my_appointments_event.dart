part of 'my_appointments_bloc.dart';

sealed class MyAppointmentsEvent {
  const MyAppointmentsEvent();
}

/// Prvo učitavanje ili „Pokušaj ponovo“: ekran prvo prikaže učitavanje.
final class MyAppointmentsRequested extends MyAppointmentsEvent {
  const MyAppointmentsRequested();
}

/// Tiho osvežavanje (npr. posle novog zakazivanja), bez ekrana za učitavanje.
final class MyAppointmentsRefreshed extends MyAppointmentsEvent {
  const MyAppointmentsRefreshed();
}

final class AppointmentConfirmationRequested extends MyAppointmentsEvent {
  const AppointmentConfirmationRequested(this.id);

  final AppointmentId id;
}

final class AppointmentCancellationRequested extends MyAppointmentsEvent {
  const AppointmentCancellationRequested(this.id);

  final AppointmentId id;
}

final class MyAppointmentsNoticeAcknowledged extends MyAppointmentsEvent {
  const MyAppointmentsNoticeAcknowledged();
}
