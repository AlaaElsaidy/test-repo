part of 'doctor_cubit.dart';

@immutable
sealed class DoctorState {}

final class DoctorInitial extends DoctorState {}

final class DoctorLoading extends DoctorState {}

final class DoctorSuccess extends DoctorState {
  List<Map<String, dynamic>> doctors;

  DoctorSuccess(this.doctors);
}

final class DoctorFailure extends DoctorState {
  String errorMessage;

  DoctorFailure(this.errorMessage);
}

final class UpdateFamilyLoading extends DoctorState {}

final class UpdateFamilySuccess extends DoctorState {}

final class UpdateFamilyFailure extends DoctorState {
  String errorMessage;

  UpdateFamilyFailure(this.errorMessage);
}
