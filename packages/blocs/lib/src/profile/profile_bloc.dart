import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

import '../clock.dart';
import '../ports/donation_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// Profil davaoca: učitavanje i čuvanje forme.
/// Pravila profila su u domenu ([updateProfile]); forma ih koristi pri unosu,
/// a Bloc ih proverava ponovo pre čuvanja.
final class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required this.repository, required this.clock, required this.donorId}) : super(const ProfileLoading()) {
    on<ProfileRequested>((event, emit) async {
      emit(const ProfileLoading());
      try {
        final donor = await repository.donor(donorId);
        emit(donor == null ? ProfileFailure(StateError('Nema davaoca ${donorId.value}')) : ProfileLoaded(donor));
      } on Exception catch (cause) {
        emit(ProfileFailure(cause));
      }
    });
    on<ProfileSubmitted>(_onSubmitted);
    on<ProfileNoticeAcknowledged>((event, emit) {
      final current = state;
      if (current is ProfileLoaded && current.notice != null) emit(ProfileLoaded(current.donor));
    });
  }

  final DonationRepository repository;
  final Clock clock;
  final DonorId donorId;

  Future<void> _onSubmitted(ProfileSubmitted event, Emitter<ProfileState> emit) async {
    final current = state;
    if (current is! ProfileLoaded || current.saving) return;
    final result = updateProfile(
      current.donor,
      name: event.name,
      birthDate: event.birthDate,
      sex: event.sex,
      bloodGroup: event.bloodGroup,
      city: event.city,
      lastDonation: event.lastDonation,
      now: clock(),
    );
    switch (result) {
      case Failure(:final error):
        emit(ProfileLoaded(current.donor, notice: ProfileRejected(error)));
      case Success(:final value):
        emit(ProfileLoaded(current.donor, saving: true));
        try {
          final saved = await repository.saveDonor(value);
          emit(ProfileLoaded(saved, notice: const ProfileSaved()));
        } on Exception catch (cause) {
          emit(ProfileLoaded(current.donor, notice: ProfileSaveFailed(cause)));
        }
    }
  }
}
