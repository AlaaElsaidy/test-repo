// lib/core/models/tracking_models.dart

class SafeZone {
  final String id;
  final String patientId;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SafeZone({
    required this.id,
    required this.patientId,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SafeZone.fromJson(Map<String, dynamic> json) => SafeZone(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeters: (json['radius_meters'] as num).toDouble(),
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  SafeZone copyWith({
    String? id,
    String? patientId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SafeZone(
        id: id ?? this.id,
        patientId: patientId ?? this.patientId,
        name: name ?? this.name,
        address: address ?? this.address,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        radiusMeters: radiusMeters ?? this.radiusMeters,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  String toString() => 'SafeZone(id: $id, name: $name, radius: $radiusMeters)';
}

class PatientLocation {
  final String id;
  final String patientId;
  final double latitude;
  final double longitude;
  final String? address;
  final double? accuracy;
  final DateTime timestamp;

  PatientLocation({
    required this.id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    this.address,
    this.accuracy,
    required this.timestamp,
  });

  factory PatientLocation.fromJson(Map<String, dynamic> json) => PatientLocation(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] as String?,
        accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() =>
      'PatientLocation(id: $id, lat: $latitude, lng: $longitude, time: $timestamp)';
}

class LocationHistory {
  final String id;
  final String patientId;
  final String? placeName;
  final String? address;
  final double latitude;
  final double longitude;
  final DateTime arrivedAt;
  final DateTime? departedAt;
  final int? durationMinutes;
  final DateTime createdAt;

  LocationHistory({
    required this.id,
    required this.patientId,
    this.placeName,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.arrivedAt,
    this.departedAt,
    this.durationMinutes,
    required this.createdAt,
  });

  factory LocationHistory.fromJson(Map<String, dynamic> json) => LocationHistory(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        placeName: json['place_name'] as String?,
        address: json['address'] as String?,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        arrivedAt: DateTime.parse(json['arrived_at'] as String),
        departedAt: json['departed_at'] != null ? DateTime.parse(json['departed_at'] as String) : null,
        durationMinutes: json['duration_minutes'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'place_name': placeName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'arrived_at': arrivedAt.toIso8601String(),
        'departed_at': departedAt?.toIso8601String(),
        'duration_minutes': durationMinutes,
        'created_at': createdAt.toIso8601String(),
      };

  bool get isCurrentlyThere => departedAt == null;

  Duration? get duration {
    if (durationMinutes == null) return null;
    return Duration(minutes: durationMinutes!);
  }

  @override
  String toString() =>
      'LocationHistory(place: $placeName, arrived: $arrivedAt, departed: $departedAt)';
}

class EmergencyContact {
  final String id;
  final String patientId;
  final String name;
  final String phone;
  final String? relationship;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyContact({
    required this.id,
    required this.patientId,
    required this.name,
    required this.phone,
    this.relationship,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        relationship: json['relationship'] as String?,
        isPrimary: json['is_primary'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'is_primary': isPrimary,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  EmergencyContact copyWith({
    String? id,
    String? patientId,
    String? name,
    String? phone,
    String? relationship,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      EmergencyContact(
        id: id ?? this.id,
        patientId: patientId ?? this.patientId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        relationship: relationship ?? this.relationship,
        isPrimary: isPrimary ?? this.isPrimary,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  String toString() => 'EmergencyContact(name: $name, phone: $phone, primary: $isPrimary)';
}
