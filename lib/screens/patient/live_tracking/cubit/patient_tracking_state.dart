// lib/screens/patient/live_tracking/cubit/patient_tracking_state.dart

part of 'patient_tracking_cubit.dart';

enum TrackingStatus { initial, loading, loaded, error }

class PatientTrackingState extends Equatable {
  final TrackingStatus status;
  final Position? currentPosition;
  final String? address;
  final DateTime? lastUpdated;
  final List<SafeZone> safeZones;
  final bool isInsideSafeZone;
  final String? errorMessage;
  final List<LocationHistory> locationHistory;
  final List<EmergencyContact> emergencyContacts;

  const PatientTrackingState({
    required this.status,
    this.currentPosition,
    this.address,
    this.lastUpdated,
    required this.safeZones,
    required this.isInsideSafeZone,
    this.errorMessage,
    required this.locationHistory,
    required this.emergencyContacts,
  });

  PatientTrackingState copyWith({
    TrackingStatus? status,
    Position? currentPosition,
    String? address,
    DateTime? lastUpdated,
    List<SafeZone>? safeZones,
    bool? isInsideSafeZone,
    String? errorMessage,
    List<LocationHistory>? locationHistory,
    List<EmergencyContact>? emergencyContacts,
  }) =>
      PatientTrackingState(
        status: status ?? this.status,
        currentPosition: currentPosition ?? this.currentPosition,
        address: address ?? this.address,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        safeZones: safeZones ?? this.safeZones,
        isInsideSafeZone: isInsideSafeZone ?? this.isInsideSafeZone,
        errorMessage: errorMessage,
        locationHistory: locationHistory ?? this.locationHistory,
        emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      );

  @override
  List<Object?> get props => [
        status,
        currentPosition,
        address,
        lastUpdated,
        safeZones,
        isInsideSafeZone,
        errorMessage,
        locationHistory,
        emergencyContacts,
      ];
}
