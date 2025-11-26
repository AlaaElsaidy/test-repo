import 'package:alzcare/screens/doctor/profile/data/profile-repo.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../../family/doctors-selection/data/doctorModel.dart';

part 'doctor_profile_state.dart';

class DoctorProfileCubit extends Cubit<DoctorProfileState> {
  DoctorProfileRepo doctorProfileRepo;

  DoctorProfileCubit(this.doctorProfileRepo) : super(DoctorProfileInitial());

  Future<void> getData({required String userId}) async {
    emit(GetDoctorDataLoading());
    var res = await doctorProfileRepo.getPatientData(userId: userId);
    res.fold(
      (l) => emit(GetDoctorDataFailure(l)),
      (r) => emit(GetDoctorDataSuccess(r)),
    );
  }
}
