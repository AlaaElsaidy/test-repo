part of 'family_tracking_cubit.dart';

class FamilyTrackingState extends Equatable {
  final FamilyTrackingStatus status;
  final TrackingTab selectedTab;
  
  // Live Tracking
  final PatientLocation? lastKnownLocation;
  final String? patientAddress;
  final bool patientInsideSafeZone;
  final SafeZone? currentZone;
  final DateTime? lastLocationUpdate;
  
  // Safe Zones Management
  final List<SafeZone> safeZones;
  final bool isCreatingZone;
  final bool isEditingZone;
  final SafeZone? selectedZone;
  
  // History & Statistics
  final List<LocationHistory> locationHistory;
  final Map<String, int> zoneVisitCounts;
  final double averageDailyDistance;
  
  // Error Handling
  final String? errorMessage;

  const FamilyTrackingState({
    required this.status,
    required this.selectedTab,
    this.lastKnownLocation,
    this.patientAddress,
    required this.patientInsideSafeZone,
    this.currentZone,
    this.lastLocationUpdate,
    required this.safeZones,
    required this.isCreatingZone,
    required this.isEditingZone,
    this.selectedZone,
    required this.locationHistory,
    required this.zoneVisitCounts,
    required this.averageDailyDistance,
    this.errorMessage,
  });

  FamilyTrackingState copyWith({
    FamilyTrackingStatus? status,
    TrackingTab? selectedTab,
    PatientLocation? lastKnownLocation,
    String? patientAddress,
    bool? patientInsideSafeZone,
    SafeZone? currentZone,
    DateTime? lastLocationUpdate,
    List<SafeZone>? safeZones,
    bool? isCreatingZone,
    bool? isEditingZone,
    SafeZone? selectedZone,
    List<LocationHistory>? locationHistory,
    Map<String, int>? zoneVisitCounts,
    double? averageDailyDistance,
    String? errorMessage,
  }) =>
      FamilyTrackingState(
        status: status ?? this.status,
        selectedTab: selectedTab ?? this.selectedTab,
        lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
        patientAddress: patientAddress ?? this.patientAddress,
        patientInsideSafeZone: patientInsideSafeZone ?? this.patientInsideSafeZone,
        currentZone: currentZone ?? this.currentZone,
        lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
        safeZones: safeZones ?? this.safeZones,
        isCreatingZone: isCreatingZone ?? this.isCreatingZone,
        isEditingZone: isEditingZone ?? this.isEditingZone,
        selectedZone: selectedZone ?? this.selectedZone,
        locationHistory: locationHistory ?? this.locationHistory,
        zoneVisitCounts: zoneVisitCounts ?? this.zoneVisitCounts,
        averageDailyDistance: averageDailyDistance ?? this.averageDailyDistance,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [
        status,
        selectedTab,
        lastKnownLocation,
        patientAddress,
        patientInsideSafeZone,
        currentZone,
        lastLocationUpdate,
        safeZones,
        isCreatingZone,
        isEditingZone,
        selectedZone,
        locationHistory,
        zoneVisitCounts,
        averageDailyDistance,
        errorMessage,
      ];
}
