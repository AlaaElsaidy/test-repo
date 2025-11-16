import 'package:alzcare/core/supabase/auth-service.dart';
import 'package:alzcare/core/supabase/supabase-service.dart';
import 'package:alzcare/screens/family/signup/data/userModel.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase/supabase.dart';

import '../../../../core/supabase/supabase-error-handler.dart';
import 'family-model.dart';

class SignUpRepo {
  AuthService authService;

  FamilyMemberService familyMemberService;

  SignUpRepo(this.authService, this.familyMemberService);

  Future<Either<String, AuthResponse>> signUp(
      UserModel userModel, String password) async {
    try {
      var auth = await authService.signUp(
          email: userModel.email,
          password: password,
          name: userModel.name,
          role: userModel.role);
      return Right(auth);
    } catch (error) {
      final errorMessage = SupabaseErrorHandler.handleError(error);
      return Left(errorMessage);
    }
  }

  Future<Either<String, void>> addFamily(
      FamilyMemberModel familyMemberModel) async {
    try {
      await familyMemberService.addFamily(
        familyId: familyMemberModel.id,
        email: familyMemberModel.email,
        name: familyMemberModel.name,
      );
      return const Right(null);
    } catch (error) {
      print(error);
      final errorMessage = SupabaseErrorHandler.handleError(error);
      return Left(errorMessage);
    }
  }
}
