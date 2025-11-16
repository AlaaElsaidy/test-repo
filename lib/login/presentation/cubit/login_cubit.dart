import 'package:alzcare/login/data/login%20repo.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:supabase/supabase.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginRepo loginRepo;

  LoginCubit(this.loginRepo) : super(LoginInitial());

  Future<void> login({required String email, required String password}) async {
    emit(LoginLoading());
    var res = await loginRepo.login(email: email, password: password);
    res.fold(
      (l) => emit(LoginFailure(l)),
      (r) => emit(LoginSuccess(r)),
    );
  }

  Future<void> getUser({required String userId}) async {
    emit(GetUserLoading());
    var res = await loginRepo.getUser(userId: userId);
    res.fold(
      (l) => emit(GetUserFailure(l)),
      (r) => emit(GetUserSuccess(r)),
    );
  }
}
