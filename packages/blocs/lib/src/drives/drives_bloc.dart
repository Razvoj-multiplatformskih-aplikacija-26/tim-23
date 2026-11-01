import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

import '../clock.dart';
import '../ports/donation_repository.dart';

part 'drives_event.dart';
part 'drives_state.dart';

/// Lista akcija davanja krvi. Mobilna aplikacija prikazuje samo predstojeće,
/// a backoffice sve, da osoblje može da izabere akciju.
final class DrivesBloc extends Bloc<DrivesEvent, DrivesState> {
  DrivesBloc({required this.repository, required this.clock, this.upcomingOnly = true})
    : super(const DrivesLoading()) {
    on<DrivesRequested>((event, emit) async {
      emit(const DrivesLoading());
      try {
        final now = clock();
        final all = await repository.drives();
        final drives = upcomingOnly ? all.where((d) => d.end.isAfter(now)).toList() : all;
        emit(drives.isEmpty ? const DrivesEmpty() : DrivesLoaded(drives));
      } on Exception catch (cause) {
        emit(DrivesFailure(cause));
      }
    });
  }

  final DonationRepository repository;
  final Clock clock;
  final bool upcomingOnly;
}
