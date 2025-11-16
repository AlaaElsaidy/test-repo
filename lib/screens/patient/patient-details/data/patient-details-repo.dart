import 'dart:io';

import 'package:alzcare/core/supabase/supabase-error-handler.dart';
import 'package:alzcare/core/supabase/supabase-service.dart';
import 'package:alzcare/screens/patient/patient-details/data/patient-model.dart';
import 'package:dartz/dartz.dart';

class PatientDetailsRepo {
  PatientService patientService;

  PatientDetailsRepo(this.patientService);

  Future<Either<String, void>> addPatient(PatientModel patientModel) async {
    try {
      await patientService.addPatient(
          patientId: patientModel.patientId,
          age: patientModel.age,
          gender: patientModel.gender,
          name: patientModel.name,
          homeAddress: patientModel.homeAddress,
          latitude: patientModel.latitude,
          longitude: patientModel.longitude,
          photoUrl: patientModel.photoUrl,
          stage: patientModel.stage);
      return const Right(null);
    } catch (e) {
      return Left(SupabaseErrorHandler.handleError(e));
    }
  }

  Future<Either<String, String>> uploadPhoto(
      {required String patientId, required File imageFile}) async {
    try {
      String imagePath =
          await patientService.uploadPatientPhoto(patientId, imageFile);
      return Right(imagePath);
    } catch (e) {
      print(e);
      print(e.toString());
      return Left(SupabaseErrorHandler.handleError(e.toString()));
    }
  }
}
