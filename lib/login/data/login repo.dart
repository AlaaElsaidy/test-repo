import 'package:alzcare/core/supabase/auth-service.dart';
import 'package:alzcare/core/supabase/supabase-error-handler.dart';
import 'package:alzcare/core/supabase/supabase-service.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase/supabase.dart';

class LoginRepo {
  AuthService authService;
  UserService userService;

  LoginRepo(this.authService, this.userService);

  Future<Either<String, AuthResponse>> login(
      {required String email, required String password}) async {
    try {
      var data = await authService.signIn(email: email, password: password);
      return Right(data);
    } catch (error) {
      return Left(SupabaseErrorHandler.handleError(error));
    }
  }

  Future<Either<String, Map<String, dynamic>?>> getUser(
      {required String userId}) async {
    try {
      var data = await userService.getUser(userId);
      return Right(data);
    } catch (error) {
      return Left(SupabaseErrorHandler.handleError(error));
    }
  }
}
