part of 'drives_bloc.dart';

/// Četiri stanja ekrana: učitavanje, greška, prazno, podaci.
sealed class DrivesState extends Equatable {
  const DrivesState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class DrivesLoading extends DrivesState {
  const DrivesLoading();
}

final class DrivesFailure extends DrivesState {
  const DrivesFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];

  @override
  String toString() => 'DrivesFailure($cause)';
}

final class DrivesEmpty extends DrivesState {
  const DrivesEmpty();
}

final class DrivesLoaded extends DrivesState {
  const DrivesLoaded(this.drives);

  final List<DonationDrive> drives;

  DonationDrive? find(DriveId id) => drives.where((d) => d.id == id).firstOrNull;

  @override
  List<Object?> get props => [drives];

  @override
  String toString() => 'DrivesLoaded(${drives.length} akcija)';
}
