class DoctorAdviceModel {
  final String id;
  final String? doctorId;
  final String? patientId;
  final String? familyMemberId;
  final String? title;
  final List<String> tips;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DoctorAdviceModel({
    required this.id,
    this.doctorId,
    this.patientId,
    this.familyMemberId,
    this.title,
    required this.tips,
    this.videoUrl,
    this.thumbnailUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DoctorAdviceModel.fromJson(Map<String, dynamic> json) {
    final tipsJson = json['tips'];
    final parsedTips = <String>[];
    if (tipsJson is List) {
      parsedTips.addAll(tipsJson.map((e) => e.toString()));
    }

    return DoctorAdviceModel(
      id: json['id'] as String,
      doctorId: json['doctor_id'] as String?,
      patientId: json['patient_id'] as String?,
      familyMemberId: json['family_member_id'] as String?,
      title: json['title'] as String?,
      tips: parsedTips,
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      status: (json['status'] as String?) ?? 'draft',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (doctorId != null) 'doctor_id': doctorId,
      if (patientId != null) 'patient_id': patientId,
      if (familyMemberId != null) 'family_member_id': familyMemberId,
      if (title != null) 'title': title,
      'tips': tips,
      if (videoUrl != null) 'video_url': videoUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DoctorAdviceModel copyWith({
    String? id,
    String? doctorId,
    String? patientId,
    String? familyMemberId,
    String? title,
    List<String>? tips,
    String? videoUrl,
    String? thumbnailUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DoctorAdviceModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      title: title ?? this.title,
      tips: tips ?? this.tips,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

