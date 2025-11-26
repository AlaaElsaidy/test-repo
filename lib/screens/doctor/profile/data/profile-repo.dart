import 'package:alzcare/core/supabase/supabase-error-handler.dart';
import 'package:alzcare/core/supabase/supabase-service.dart';
import 'package:dartz/dartz.dart';

import '../../../family/doctors-selection/data/doctorModel.dart';

class DoctorProfileRepo {
  DoctorService doctorService;

  DoctorProfileRepo(this.doctorService);

  Future<Either<String, Doctor>> getPatientData(
      {required String userId}) async {
    try {
      var data = await doctorService.getDoctorByUserId(userId);
      return Right(Doctor.fromJson(data!));
    } catch (error) {
      return Left(SupabaseErrorHandler.handleError(error));
    }
  }
}
