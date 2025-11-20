import 'package:alzcare/core/models/invitation-model.dart';

abstract class InvitationState {
  const InvitationState();
}

class InvitationInitial extends InvitationState {}

class InvitationLoading extends InvitationState {}

class InvitationSuccess extends InvitationState {
  final InvitationModel invitation;

  const InvitationSuccess(this.invitation);
}

class InvitationFailure extends InvitationState {
  final String errorMessage;

  const InvitationFailure(this.errorMessage);
}

class InvitationsListSuccess extends InvitationState {
  final List<InvitationModel> invitations;

  const InvitationsListSuccess(this.invitations);
}

class InvitationAccepted extends InvitationState {}

class InvitationRejected extends InvitationState {}

