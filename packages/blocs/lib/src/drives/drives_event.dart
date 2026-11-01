part of 'drives_bloc.dart';

/// Događaji se imenuju u prošlom vremenu: šta se desilo.
sealed class DrivesEvent {
  const DrivesEvent();
}

/// Ekran je otvoren ili korisnik traži ponovno učitavanje.
final class DrivesRequested extends DrivesEvent {
  const DrivesRequested();
}
