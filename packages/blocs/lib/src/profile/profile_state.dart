part of 'profile_bloc.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileFailure extends ProfileState {
  const ProfileFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];

  @override
  String toString() => 'ProfileFailure($cause)';
}

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.donor, {this.saving = false, this.notice});

  final Donor donor;
  final bool saving;
  final ProfileNotice? notice;

  @override
  List<Object?> get props => [donor, saving, notice];

  @override
  String toString() => 'ProfileLoaded(${donor.name}${saving ? ', čuva se' : ''}${notice == null ? '' : ', ${notice.runtimeType}'})';
}

sealed class ProfileNotice extends Equatable {
  const ProfileNotice();

  @override
  List<Object?> get props => const [];
}

final class ProfileSaved extends ProfileNotice {
  const ProfileSaved();
}

final class ProfileRejected extends ProfileNotice {
  const ProfileRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

final class ProfileSaveFailed extends ProfileNotice {
  const ProfileSaveFailed(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}
