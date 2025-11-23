// lib/screens/family/tracking/family_tracking_example.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/repositories/tracking_repository.dart';
import '../../../core/utils/location_utils.dart';
import 'cubit/family_tracking_cubit.dart';

/// مثال على استخدام FamilyTrackingCubit في الشاشة
class FamilyTrackingExample extends StatelessWidget {
  final String patientId;

  const FamilyTrackingExample({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FamilyTrackingCubit(
        getIt<TrackingRepository>(),
        patientId,
      )..initializeTracking(),
      child: const FamilyTrackingScreen(),
    );
  }
}

class FamilyTrackingScreen extends StatefulWidget {
  const FamilyTrackingScreen({Key? key}) : super(key: key);

  @override
  State<FamilyTrackingScreen> createState() => _FamilyTrackingScreenState();
}

class _FamilyTrackingScreenState extends State<FamilyTrackingScreen> {
  late GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع المريض'),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocListener<FamilyTrackingCubit, FamilyTrackingState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'خطأ غير معروف'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<FamilyTrackingCubit, FamilyTrackingState>(
          builder: (context, state) {
            return DefaultTabController(
              length: 3,
              child: Scaffold(
                appBar: TabBar(
                  onTap: (index) {
                    final tabs = [
                      TrackingTab.live,
                      TrackingTab.safeZones,
                      TrackingTab.history,
                    ];
                    context
                        .read<FamilyTrackingCubit>()
                        .selectTab(tabs[index]);
                  },
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.location_on),
                      text: 'التتبع المباشر',
                    ),
                    Tab(
                      icon: Icon(Icons.security),
                      text: 'المناطق الآمنة',
                    ),
                    Tab(
                      icon: Icon(Icons.history),
                      text: 'السجل',
                    ),
                  ],
                ),
                body: TabBarView(
                  children: [
                    // Tab 1: Live Tracking
                    _buildLiveTab(context, state),
                    // Tab 2: Safe Zones
                    _buildSafeZonesTab(context, state),
                    // Tab 3: History
                    _buildHistoryTab(context, state),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLiveTab(BuildContext context, FamilyTrackingState state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Map
          if (state.lastKnownLocation != null)
            Container(
              height: 300,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: GoogleMap(
                onMapCreated: (controller) {
                  mapController = controller;
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    state.lastKnownLocation!.latitude,
                    state.lastKnownLocation!.longitude,
                  ),
                  zoom: 15,
                ),
                markers: {
                  // Patient location
                  Marker(
                    markerId: const MarkerId('patient'),
                    position: LatLng(
                      state.lastKnownLocation!.latitude,
                      state.lastKnownLocation!.longitude,
                    ),
                    icon: BitmapDescriptor.defaultMarker,
                    infoWindow: const InfoWindow(title: 'موقع المريض'),
                  ),
                  // Safe zone markers
                  ...state.safeZones.map((zone) {
                    return Marker(
                      markerId: MarkerId('zone-${zone.id}'),
                      position: LatLng(zone.latitude, zone.longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        zone.isActive
                            ? BitmapDescriptor.hueGreen
                            : BitmapDescriptor.hueRed,
                      ),
                      infoWindow: InfoWindow(title: zone.name),
                    );
                  }),
                },
                circles: state.safeZones
                    .where((z) => z.isActive)
                    .map((zone) {
                  return Circle(
                    circleId: CircleId('circle-${zone.id}'),
                    center: LatLng(zone.latitude, zone.longitude),
                    radius: zone.radiusMeters,
                    fillColor: Colors.blue.withOpacity(0.2),
                    strokeColor: Colors.blue,
                    strokeWidth: 2,
                  );
                }).toSet(),
              ),
            )
          else
            Container(
              height: 300,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),

          // Status Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Safety Status
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: state.patientInsideSafeZone
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          state.patientInsideSafeZone
                              ? 'داخل منطقة آمنة'
                              : 'خارج المناطق الآمنة',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Current Zone
                    if (state.currentZone != null)
                      Text(
                        'المنطقة: ${state.currentZone!.name}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                    const SizedBox(height: 12),

                    // Last Update
                    if (state.lastLocationUpdate != null)
                      Text(
                        'آخر تحديث: ${state.lastLocationUpdate!.hour}:${state.lastLocationUpdate!.minute}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSafeZonesTab(BuildContext context, FamilyTrackingState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: () {
            _showAddSafeZoneDialog(context);
          },
          icon: const Icon(Icons.add),
          label: const Text('إضافة منطقة آمنة'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 16),
        if (state.safeZones.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'لا توجد مناطق آمنة',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.safeZones.length,
            itemBuilder: (context, index) {
              final zone = state.safeZones[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: zone.isActive ? Colors.green : Colors.grey,
                  ),
                  title: Text(zone.name),
                  subtitle: Text('نصف القطر: ${formatDistance(zone.radiusMeters)}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('تعديل'),
                        onTap: () {
                          context
                              .read<FamilyTrackingCubit>()
                              .selectZoneForEditing(zone);
                        },
                      ),
                      PopupMenuItem(
                        child: const Text('حذف'),
                        onTap: () {
                          context
                              .read<FamilyTrackingCubit>()
                              .deleteSafeZone(zone.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildHistoryTab(BuildContext context, FamilyTrackingState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإحصائيات',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'عدد الزيارات',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${state.zoneVisitCounts.length}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'متوسط المسافة اليومية',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          formatDistance(state.averageDailyDistance),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'آخر التحركات',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (state.locationHistory.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'لا توجد بيانات سابقة',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.locationHistory.length,
            itemBuilder: (context, index) {
              final entry = state.locationHistory[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    entry.isCurrentlyThere ? Icons.check_circle : Icons.history,
                    color:
                        entry.isCurrentlyThere ? Colors.green : Colors.orange,
                  ),
                  title: Text(entry.placeName ?? 'مكان غير معروف'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'الوصول: ${entry.arrivedAt.hour}:${entry.arrivedAt.minute}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (entry.departedAt != null)
                        Text(
                          'المغادرة: ${entry.departedAt!.hour}:${entry.departedAt!.minute}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (entry.duration != null)
                        Text(
                          'المدة: ${entry.duration!.inMinutes} دقيقة',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddSafeZoneDialog(BuildContext context) {
    final nameController = TextEditingController();
    final radiusController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة منطقة آمنة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'اسم المنطقة'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: radiusController,
              decoration: const InputDecoration(hintText: 'نصف القطر (متر)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  radiusController.text.isNotEmpty) {
                context.read<FamilyTrackingCubit>().addSafeZone(
                      name: nameController.text,
                      latitude: 0.0, // استخدم الموقع الحالي
                      longitude: 0.0,
                      radiusMeters: double.parse(radiusController.text),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
