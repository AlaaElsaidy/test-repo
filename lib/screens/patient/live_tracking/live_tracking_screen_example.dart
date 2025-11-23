// lib/screens/patient/live_tracking/live_tracking_screen_example.dart
// مثال على كيفية استخدام PatientTrackingCubit في الشاشة

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/repositories/tracking_repository.dart';
import '../../../core/utils/location_utils.dart';
import 'cubit/patient_tracking_cubit.dart';

class LiveTrackingScreenExample extends StatelessWidget {
  final String patientId;

  const LiveTrackingScreenExample({
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تتبع الموقع'),
          centerTitle: true,
          elevation: 0,
        ),
        body: BlocBuilder<PatientTrackingCubit, PatientTrackingState>(
          builder: (context, state) {
            if (state.status == TrackingStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == TrackingStatus.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage ?? 'حدث خطأ ما',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<PatientTrackingCubit>().initializeTracking();
                      },
                      child: const Text('حاول مجددًا'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  // بطاقة حالة الأمان
                  _buildSafetyStatusCard(context, state),
                  const SizedBox(height: 16),

                  // معلومات الموقع الحالي
                  if (state.currentPosition != null)
                    _buildLocationInfoCard(state),
                  const SizedBox(height: 16),

                  // المناطق الآمنة
                  _buildSafeZonesSection(context, state),
                  const SizedBox(height: 16),

                  // السجل الأخير
                  _buildRecentHistorySection(state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// بطاقة حالة الأمان
  Widget _buildSafetyStatusCard(
    BuildContext context,
    PatientTrackingState state,
  ) {
    final isInside = state.isInsideSafeZone;
    final zoneName = state.safeZones.isNotEmpty
        ? state.safeZones.first.name
        : 'لا توجد مناطق آمنة';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: isInside ? Colors.green[50] : Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isInside ? Icons.check_circle : Icons.warning,
                color: isInside ? Colors.green : Colors.orange,
                size: 48,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isInside ? 'أنت آمن' : 'تحذير',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isInside
                          ? 'أنت موجود في $zoneName'
                          : 'أنت خارج المناطق الآمنة',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (!isInside)
                ElevatedButton.icon(
                  onPressed: () {
                    // تنبيه الأهل
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال تنبيه')),
                    );
                  },
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('تنبيه'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// بطاقة معلومات الموقع
  Widget _buildLocationInfoCard(PatientTrackingState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'موقعك الحالي',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                state.address ?? 'جاري تحديد الموقع...',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${state.currentPosition?.latitude.toStringAsFixed(4)}, '
                    '${state.currentPosition?.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(state.lastUpdated),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// قسم المناطق الآمنة
  Widget _buildSafeZonesSection(
    BuildContext context,
    PatientTrackingState state,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المناطق الآمنة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  // فتح شاشة إضافة منطقة جديدة
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('قريباً: إضافة منطقة جديدة')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('إضافة'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.safeZones.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'لا توجد مناطق آمنة',
                  style: TextStyle(color: Colors.grey[600]),
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      zone.isActive ? Icons.check_circle : Icons.circle_outlined,
                      color: zone.isActive ? Colors.green : Colors.grey,
                    ),
                    title: Text(zone.name),
                    subtitle: Text(
                      formatDistance(zone.radiusMeters),
                      style: const TextStyle(fontSize: 12),
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
    );
  }

  /// قسم السجل الأخير
  Widget _buildRecentHistorySection(PatientTrackingState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'السجل الأخير',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (state.locationHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'لا يوجد سجل',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.locationHistory.take(5).length,
              itemBuilder: (context, index) {
                final entry = state.locationHistory[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.location_history),
                    title: Text(
                      entry.placeName ?? 'موقع غير معروف',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatTime(entry.arrivedAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: entry.isCurrentlyThere
                        ? const Chip(
                            label: Text('الآن'),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        : Text(
                            '${entry.duration?.inMinutes ?? 0} دقيقة',
                            style: const TextStyle(fontSize: 12),
                          ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'قبل ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'قبل ${difference.inHours} ساعة';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
