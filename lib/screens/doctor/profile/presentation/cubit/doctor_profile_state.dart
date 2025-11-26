part of 'doctor_profile_cubit.dart';

@immutable
sealed class DoctorProfileState {}

final class DoctorProfileInitial extends DoctorProfileState {}

final class GetDoctorDataLoading extends DoctorProfileState {}

final class GetDoctorDataSuccess extends DoctorProfileState {
  Doctor doctor;

  GetDoctorDataSuccess(this.doctor);
}

final class GetDoctorDataFailure extends DoctorProfileState {
  String errorMessage;

  GetDoctorDataFailure(this.errorMessage);
}
