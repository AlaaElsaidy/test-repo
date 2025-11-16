import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../data/doctor-repo.dart';

part 'doctor_state.dart';

class DoctorCubit extends Cubit<DoctorState> {
  DoctorRepo doctorRepo;

  DoctorCubit(this.doctorRepo) : super(DoctorInitial());

  Future<void> getDoctors() async {
    emit(DoctorLoading());
    var data = await doctorRepo.getDoctors();
    data.fold(
      (l) => emit(DoctorFailure(l)),
      (r) => emit(DoctorSuccess(r)),
    );
  }

  Future<void> updateFamily(
      {required String familyId, required Map<String, dynamic> data}) async {
    emit(UpdateFamilyLoading());
    var res = await doctorRepo.updateFamily(familyId: familyId, data: data);
    res.fold(
      (l) => emit(UpdateFamilyFailure(l)),
      (r) => emit(UpdateFamilySuccess()),
    );
  }
}
