import 'dart:io';

import 'package:alzcare/screens/patient/patient-details/data/patient-details-repo.dart';
import 'package:alzcare/screens/patient/patient-details/data/patient-model.dart';
import 'package:bloc/bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta/meta.dart';

import '../../../../../core/geolocator/geolocator-service.dart';

part 'patient_details_state.dart';

class PatientDetailsCubit extends Cubit<PatientDetailsState> {
  PatientDetailsRepo patientDetailsRepo;

  PatientDetailsCubit(this.patientDetailsRepo) : super(PatientDetailsInitial());

  Future<void> addPatient(PatientModel patientModel) async {
    emit(PatientDetailsLoading());
    var data = await patientDetailsRepo.addPatient(patientModel);
    data.fold(
      (l) => emit(PatientDetailsFailure(l)),
      (r) => emit(PatientDetailsSuccess()),
    );
  }

  Future<void> uploadPhoto(String patientId, File imageFile) async {
    emit(PatientUploadPhotoLoading());
    var data = await patientDetailsRepo.uploadPhoto(
        patientId: patientId, imageFile: imageFile);
    data.fold(
      (l) => emit(PatientUploadPhotoFailure(l)),
      (r) => emit(PatientUploadPhotoSuccess(r)),
    );
  }

  /// Upload photo and return URL directly (for synchronous use)
  Future<String?> uploadPhotoAndGetUrl(String patientId, File imageFile) async {
    final result = await patientDetailsRepo.uploadPhoto(
        patientId: patientId, imageFile: imageFile);
    return result.fold(
      (error) => null,
      (url) => url,
    );
  }

  Future<void> getLocation() async {
    emit(GetLocationLoading());
    var data = await getCurrentLocation();
    if (data.position != null) {
      emit(GetLocationSuccess(data.position!));
    }
    if (data.error != null) {
      emit(GetLocationFailure(data.error!));
    }
  }
}
