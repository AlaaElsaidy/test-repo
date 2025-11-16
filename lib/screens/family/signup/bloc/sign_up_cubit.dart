import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:supabase/supabase.dart';

import '../data/family-model.dart';
import '../data/signup-repo.dart';
import '../data/userModel.dart';

part 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit(this.signUpRepo) : super(SignUpInitial());
  SignUpRepo signUpRepo;

  Future<void> signUp(UserModel userModel, String password) async {
    emit(SignUpLoading());
    var data = await signUpRepo.signUp(userModel, password);
    data.fold(
      (l) => emit(SignUpFailure(l)),
      (r) => emit(SignUpSuccess(r)),
    );
  }

  Future<void> addFamily(FamilyMemberModel familyMemberModel) async {
    emit(AddFamilyLoading());
    var data = await signUpRepo.addFamily(familyMemberModel);
    data.fold(
      (l) => emit(AddFamilyFailure(l)),
      (r) => emit(AddFamilySuccess()),
    );
  }
}
