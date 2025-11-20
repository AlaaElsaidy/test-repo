import 'package:alzcare/screens/patient/invitations/data/invitation-repo.dart';
import 'package:bloc/bloc.dart';

import 'invitation_state.dart';

class InvitationCubit extends Cubit<InvitationState> {
  final InvitationRepo invitationRepo;

  InvitationCubit(this.invitationRepo) : super(InvitationInitial());

  Future<void> createInvitation({
    required String patientId,
    String? familyMemberEmail,
    String? familyMemberPhone,
  }) async {
    emit(InvitationLoading());
    final result = await invitationRepo.createInvitation(
      patientId: patientId,
      familyMemberEmail: familyMemberEmail,
      familyMemberPhone: familyMemberPhone,
    );

    result.fold(
      (error) => emit(InvitationFailure(error)),
      (invitation) => emit(InvitationSuccess(invitation)),
    );
  }

  Future<void> createInvitationFromFamily({
    required String familyMemberId,
    String? patientEmail,
    String? patientPhone,
  }) async {
    emit(InvitationLoading());
    final result = await invitationRepo.createInvitationFromFamily(
      familyMemberId: familyMemberId,
      patientEmail: patientEmail,
      patientPhone: patientPhone,
    );

    result.fold(
      (error) => emit(InvitationFailure(error)),
      (invitation) => emit(InvitationSuccess(invitation)),
    );
  }

  Future<void> getInvitationByCode(String code) async {
    emit(InvitationLoading());
    final result = await invitationRepo.getInvitationByCode(code);

    result.fold(
      (error) => emit(InvitationFailure(error)),
      (invitation) {
        if (invitation == null) {
          emit(const InvitationFailure('Invitation not found'));
        } else {
          emit(InvitationSuccess(invitation));
        }
      },
    );
  }

  Future<void> acceptInvitation({
    required String invitationCode,
    required String patientId,
  }) async {
    emit(InvitationLoading());
    final result = await invitationRepo.acceptInvitation(
      invitationCode: invitationCode,
      patientId: patientId,
    );

    result.fold(
      (error) => emit(InvitationFailure(error)),
      (_) => emit(InvitationAccepted()),
    );
  }

  Future<void> rejectInvitation(String code) async {
    emit(InvitationLoading());
    final result = await invitationRepo.rejectInvitation(code);

    result.fold(
      (error) => emit(InvitationFailure(error)),
      (_) => emit(InvitationRejected()),
    );
  }

  Future<void> getInvitationsByPatient(String patientId) async {
    emit(InvitationLoading());
    final result = await invitationRepo.getInvitationsByPatient(patientId);

    result.fold(
      (error) => emit(InvitationFailure(error)),
      (invitations) => emit(InvitationsListSuccess(invitations)),
    );
  }

  Future<void> getInvitationsByFamily({
    String? email,
    String? phone,
  }) async {
    emit(InvitationLoading());
    final result = await invitationRepo.getInvitationsByFamily(
      email: email,
      phone: phone,
    );

    result.fold(
      (error) => emit(InvitationFailure(error)),
      (invitations) => emit(InvitationsListSuccess(invitations)),
    );
  }

  Future<void> getInvitationsByFamilyMember(String familyMemberId) async {
    emit(InvitationLoading());
    final result = await invitationRepo.getInvitationsByFamilyMember(familyMemberId);

    result.fold(
      (error) => emit(InvitationFailure(error)),
      (invitations) => emit(InvitationsListSuccess(invitations)),
    );
  }
}

