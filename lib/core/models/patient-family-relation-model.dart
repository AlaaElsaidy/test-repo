class PatientFamilyRelationModel {
  final String? id;
  final String patientId;
  final String familyMemberId;
  final String? relationType; // 'spouse', 'child', 'sibling', 'parent', 'other'
  final DateTime createdAt;

  PatientFamilyRelationModel({
    this.id,
    required this.patientId,
    required this.familyMemberId,
    this.relationType,
    required this.createdAt,
  });

  factory PatientFamilyRelationModel.fromJson(Map<String, dynamic> json) {
    return PatientFamilyRelationModel(
      id: json['id'],
      patientId: json['patient_id'],
      familyMemberId: json['family_member_id'],
      relationType: json['relation_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      'family_member_id': familyMemberId,
      if (relationType != null) 'relation_type': relationType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}



