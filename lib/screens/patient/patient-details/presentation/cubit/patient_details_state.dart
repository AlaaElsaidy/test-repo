part of 'patient_details_cubit.dart';

@immutable
sealed class PatientDetailsState {}

final class PatientDetailsInitial extends PatientDetailsState {}

final class PatientDetailsLoading extends PatientDetailsState {}

final class PatientDetailsSuccess extends PatientDetailsState {}

final class PatientDetailsFailure extends PatientDetailsState {
  String errorMessage;

  PatientDetailsFailure(this.errorMessage);
}

final class PatientUploadPhotoLoading extends PatientDetailsState {}

final class PatientUploadPhotoSuccess extends PatientDetailsState {
  String imagePath;

  PatientUploadPhotoSuccess(this.imagePath);
}

final class PatientUploadPhotoFailure extends PatientDetailsState {
  String errorMessage;

  PatientUploadPhotoFailure(this.errorMessage);
}

final class GetLocationLoading extends PatientDetailsState {}

final class GetLocationSuccess extends PatientDetailsState {
  Position position;

  GetLocationSuccess(this.position);
}

final class GetLocationFailure extends PatientDetailsState {
  String errorMessage;

  GetLocationFailure(this.errorMessage);
}
