class InvitationModel {
  final String? id;
  final String? patientId; // Optional for family-to-patient invitations
  final String? familyMemberEmail;
  final String? familyMemberPhone;
  final String? patientEmail; // For family-to-patient invitations
  final String? patientPhone; // For family-to-patient invitations
  final String? familyMemberId; // For family-to-patient invitations
  final String? invitationType; // 'patient_to_family' or 'family_to_patient'
  final String invitationCode;
  final String status; // 'pending', 'accepted', 'rejected', 'expired'
  final DateTime createdAt;
  final DateTime expiresAt;

  InvitationModel({
    this.id,
    this.patientId,
    this.familyMemberEmail,
    this.familyMemberPhone,
    this.patientEmail,
    this.patientPhone,
    this.familyMemberId,
    this.invitationType,
    required this.invitationCode,
    this.status = 'pending',
    required this.createdAt,
    required this.expiresAt,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'],
      patientId: json['patient_id'],
      familyMemberEmail: json['family_member_email'],
      familyMemberPhone: json['family_member_phone'],
      patientEmail: json['patient_email'],
      patientPhone: json['patient_phone'],
      familyMemberId: json['family_member_id'],
      invitationType: json['invitation_type'],
      invitationCode: json['invitation_code'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (familyMemberEmail != null) 'family_member_email': familyMemberEmail,
      if (familyMemberPhone != null) 'family_member_phone': familyMemberPhone,
      if (patientEmail != null) 'patient_email': patientEmail,
      if (patientPhone != null) 'patient_phone': patientPhone,
      if (familyMemberId != null) 'family_member_id': familyMemberId,
      if (invitationType != null) 'invitation_type': invitationType,
      'invitation_code': invitationCode,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == 'pending' && !isExpired;
  
  // Helper to determine invitation direction
  bool get isFamilyToPatient => invitationType == 'family_to_patient' || (patientEmail != null || patientPhone != null);
  bool get isPatientToFamily => invitationType == 'patient_to_family' || (familyMemberEmail != null || familyMemberPhone != null);
}



