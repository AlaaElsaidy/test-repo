// lib/screens/family/tracking/family_tracking_screen_example.dart
// مثال على كيفية استخدام FamilyTrackingCubit في شاشة العائلة

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/repositories/tracking_repository.dart';
import '../../../core/utils/location_utils.dart';
import 'cubit/family_tracking_cubit.dart';

class FamilyTrackingScreenExample extends StatelessWidget {
  final String patientId;
  final String patientName;

  const FamilyTrackingScreenExample({
    Key? key,
    required this.patientId,
    required this.patientName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FamilyTrackingCubit(
        getIt<TrackingRepository>(),
        patientId,
      )..initializeTracking(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('تتبع $patientName'),
          centerTitle: true,
          elevation: 0,
        ),
        body: BlocBuilder<FamilyTrackingCubit, FamilyTrackingState>(
          builder: (context, state) {
            if (state.status == FamilyTrackingStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == FamilyTrackingStatus.error) {
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
                        context.read<FamilyTrackingCubit>().initializeTracking();
                      },
                      child: const Text('حاول مجددًا'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // عنوان التبويبات
                _buildTabButtons(context, state),
                const SizedBox(height: 8),

                // محتوى التبويب
                Expanded(
                  child: PageView(
                    onPageChanged: (index) {
                      final tabs = [
                        TrackingTab.live,
                        TrackingTab.safeZones,
                        TrackingTab.history,
                      ];
                      if (index < tabs.length) {
                        context.read<FamilyTrackingCubit>().selectTab(tabs[index]);
                      }
                    },
                    children: [
                      _buildLiveTab(context, state),
                      _buildSafeZonesTab(context, state),
                      _buildHistoryTab(state),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// أزرار التبويبات
  Widget _buildTabButtons(
    BuildContext context,
    FamilyTrackingState state,
  ) {
    final tabs = const [
      {'tab': TrackingTab.live, 'icon': Icons.location_on, 'label': 'حي'},
      {'tab': TrackingTab.safeZones, 'icon': Icons.safety_divider, 'label': 'المناطق'},
      {'tab': TrackingTab.history, 'icon': Icons.history, 'label': 'السجل'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tabData in tabs)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                onSelected: (_) {
                  context.read<FamilyTrackingCubit>().selectTab(
                    tabData['tab'] as TrackingTab,
                  );
                },
                selected: state.selectedTab == tabData['tab'],
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tabData['icon'] as IconData, size: 16),
                    const SizedBox(width: 4),
                    Text(tabData['label'] as String),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// تبويب البث المباشر
  Widget _buildLiveTab(BuildContext context, FamilyTrackingState state) {
    final isInside = state.patientInsideSafeZone;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // بطاقة حالة الأمان
          Card(
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
                          isInside ? 'آمن' : 'تحذير',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (state.currentZone != null)
                          Text(
                            'في ${state.currentZone!.name}',
                            style: const TextStyle(color: Colors.grey),
                          )
                        else
                          Text(
                            isInside ? 'بموقع معروف' : 'خارج المناطق الآمنة',
                            style: const TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // بطاقة الموقع الحالي
          if (state.lastKnownLocation != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'آخر موقع معروف',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(state.patientAddress ?? 'جاري تحديد الموقع...'),
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
                          _formatTime(state.lastLocationUpdate),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// تبويب المناطق الآمنة
  Widget _buildSafeZonesTab(BuildContext context, FamilyTrackingState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.safeZones.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                // فتح شاشة إضافة منطقة جديدة
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('قريباً: إضافة منطقة جديدة')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('إضافة منطقة آمنة جديدة'),
            ),
          );
        }

        final zone = state.safeZones[index - 1];
        final visitCount = state.zoneVisitCounts[zone.name] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: ListTile(
              leading: Icon(
                zone.isActive ? Icons.check_circle : Icons.circle_outlined,
                color: zone.isActive ? Colors.green : Colors.grey,
              ),
              title: Text(zone.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zone.address ?? 'بدون عنوان',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(Icons.circle_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(formatDistance(zone.radiusMeters), style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 16),
                      Icon(Icons.location_history, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('$visitCount زيارة', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
              trailing: Switch(
                value: zone.isActive,
                onChanged: (value) {
                  context
                      .read<FamilyTrackingCubit>()
                      .toggleSafeZone(zone.id, value);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// تبويب السجل
  Widget _buildHistoryTab(FamilyTrackingState state) {
    if (state.locationHistory.isEmpty) {
      return Center(
        child: Text(
          'لا يوجد سجل',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.locationHistory.length,
      itemBuilder: (context, index) {
        final entry = state.locationHistory[index];
        final isToday = DateTime.now().difference(entry.arrivedAt).inDays == 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: ListTile(
              leading: Icon(
                Icons.location_history,
                color: isToday ? Colors.blue : Colors.grey,
              ),
              title: Text(entry.placeName ?? 'موقع غير معروف'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTime(entry.arrivedAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (!entry.isCurrentlyThere && entry.duration != null)
                    Text(
                      'مدة التواجد: ${entry.duration!.inHours}س ${entry.duration!.inMinutes % 60}د',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
              trailing: entry.isCurrentlyThere
                  ? const Chip(
                      label: Text('الآن'),
                      backgroundColor: Colors.blue,
                      labelStyle: TextStyle(color: Colors.white),
                    )
                  : null,
            ),
          ),
        );
      },
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
    } else if (difference.inDays == 1) {
      return 'أمس الساعة ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} الساعة ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
