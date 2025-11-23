// lib/screens/patient/live_tracking/patient_live_tracking_example.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/repositories/tracking_repository.dart';
import '../../../core/utils/location_utils.dart';
import 'cubit/patient_tracking_cubit.dart';

/// مثال على استخدام PatientTrackingCubit في الشاشة
class PatientLiveTrackingExample extends StatelessWidget {
  final String patientId;

  const PatientLiveTrackingExample({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PatientTrackingCubit(
        getIt<TrackingRepository>(),
        patientId,
      )..initializeTracking(),
      child: const PatientLiveTrackingScreen(),
    );
  }
}

class PatientLiveTrackingScreen extends StatefulWidget {
  const PatientLiveTrackingScreen({Key? key}) : super(key: key);

  @override
  State<PatientLiveTrackingScreen> createState() =>
      _PatientLiveTrackingScreenState();
}

class _PatientLiveTrackingScreenState extends State<PatientLiveTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التتبع المباشر للمريض'),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocListener<PatientTrackingCubit, PatientTrackingState>(
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
        child: BlocBuilder<PatientTrackingCubit, PatientTrackingState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Map Container
                  if (state.currentPosition != null)
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
                      child: const Center(
                        child: Text(
                          'خريطة المناطق الآمنة',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else if (state.status == TrackingStatus.loading)
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
                                    color: state.isInsideSafeZone
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  state.isInsideSafeZone
                                      ? 'داخل منطقة آمنة'
                                      : 'خارج المناطق الآمنة',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Location Details
                            if (state.currentPosition != null) ...[
                              Text(
                                'الموقع: ${state.currentPosition!.latitude.toStringAsFixed(4)}, '
                                '${state.currentPosition!.longitude.toStringAsFixed(4)}',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              if (state.address != null)
                                Text(
                                  'العنوان: ${state.address}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],

                            const SizedBox(height: 8),

                            // Last Update
                            if (state.lastUpdated != null)
                              Text(
                                'آخر تحديث: ${state.lastUpdated!.hour}:${state.lastUpdated!.minute}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Safe Zones Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المناطق الآمنة (${state.safeZones.length})',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        if (state.safeZones.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'لا توجد مناطق آمنة محددة',
                                style: Theme.of(context).textTheme.bodyMedium,
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
                                    color: zone.isActive
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  title: Text(zone.name),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      if (zone.address != null)
                                        Text(
                                          zone.address!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      Text(
                                        'نصف القطر: ${formatDistance(zone.radiusMeters)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                      ),
                                    ],
                                  ),
                                  trailing: Switch(
                                    value: zone.isActive,
                                    onChanged: (value) {
                                      context
                                          .read<PatientTrackingCubit>()
                                          .toggleSafeZone(zone.id, value);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Refresh Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context
                            .read<PatientTrackingCubit>()
                            .refreshLocation();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('تحديث الموقع'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
