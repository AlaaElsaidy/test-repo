import 'package:alzcare/core/supabase/supabase-error-handler.dart';
import 'package:alzcare/core/supabase/supabase-service.dart';
import 'package:dartz/dartz.dart';

class DoctorRepo {
  DoctorService doctorService;
  FamilyMemberService familyMemberService;

  DoctorRepo(this.doctorService, this.familyMemberService);

  Future<Either<String, List<Map<String, dynamic>>>> getDoctors() async {
    try {
      var data = await doctorService.getDoctors();
      return Right(data);
    } catch (error) {
      return Left(SupabaseErrorHandler.handleError(error));
    }
  }

  Future<Either<String, void>> updateFamily(
      {required String familyId, required Map<String, dynamic> data}) async {
    try {
      await familyMemberService.updateFamily(familyId, data);
      return const Right(null);
    } catch (error) {
      return Left(SupabaseErrorHandler.handleError(error));
    }
  }
}
