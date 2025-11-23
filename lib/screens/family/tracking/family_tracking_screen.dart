// lib/screens/family/tracking/family_tracking_screen.dart
// شاشة التتبع للعائلة - ربط كامل مع Supabase

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/models/tracking_models.dart';
import '../../../core/repositories/tracking_repository.dart';
import '../../../core/utils/location_utils.dart';
import 'cubit/family_tracking_cubit.dart';
import 'widgets/add_safe_zone_dialog.dart';

class FamilyTrackingScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const FamilyTrackingScreen({
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
      child: _FamilyTrackingContent(patientName: patientName),
    );
  }
}

class _FamilyTrackingContent extends StatelessWidget {
  final String patientName;

  const _FamilyTrackingContent({
    Key? key,
    required this.patientName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                  Icon(Icons.error_outline, 
                    size: 64, 
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(state.errorMessage ?? 'حدث خطأ'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.read<FamilyTrackingCubit>()
                        .initializeTracking(),
                    child: const Text('إعادة محاولة'),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                // الرأس
                _buildHeader(context, state),

                // التبويبات
                _buildTabs(context, state),

                // المحتوى
                Expanded(
                  child: _buildTabContent(context, state),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// بناء الرأس
  Widget _buildHeader(BuildContext context, FamilyTrackingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[600]!, Colors.teal[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Tracking',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  patientName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // TODO: فتح الإعدادات
            },
          ),
        ],
      ),
    );
  }

  /// بناء التبويبات
  Widget _buildTabs(BuildContext context, FamilyTrackingState state) {
    return Container(
      color: Colors.teal[600],
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _buildTabButton(
            context: context,
            label: 'Live',
            icon: Icons.location_on,
            isActive: state.selectedTab == TrackingTab.live,
            onTap: () => context.read<FamilyTrackingCubit>()
                .selectTab(TrackingTab.live),
          ),
          _buildTabButton(
            context: context,
            label: 'Safe Zones',
            icon: Icons.shield,
            isActive: state.selectedTab == TrackingTab.safeZones,
            onTap: () => context.read<FamilyTrackingCubit>()
                .selectTab(TrackingTab.safeZones),
          ),
          _buildTabButton(
            context: context,
            label: 'History',
            icon: Icons.history,
            isActive: state.selectedTab == TrackingTab.history,
            onTap: () => context.read<FamilyTrackingCubit>()
                .selectTab(TrackingTab.history),
          ),
        ],
      ),
    );
  }

  /// زر التبويب
  Widget _buildTabButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isActive ? Colors.teal[600] : Colors.white,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.teal[600] : Colors.white,
                      fontSize: 11,
                      fontWeight: 
                          isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// محتوى التبويب
  Widget _buildTabContent(
    BuildContext context, 
    FamilyTrackingState state,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (state.selectedTab == TrackingTab.live)
            _buildLiveTab(context, state),
          if (state.selectedTab == TrackingTab.safeZones)
            _buildSafeZonesTab(context, state),
          if (state.selectedTab == TrackingTab.history)
            _buildHistoryTab(context, state),
        ],
      ),
    );
  }

  /// تبويب Live
  Widget _buildLiveTab(BuildContext context, FamilyTrackingState state) {
    if (state.lastKnownLocation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_disabled, 
              size: 64, 
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text('لم يتم العثور على موقع'),
          ],
        ),
      );
    }

    final location = state.lastKnownLocation!;
    final isInside = state.patientInsideSafeZone;

    return Column(
      children: [
        // دائرة Safe Zone
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isInside ? Colors.green : Colors.red).withOpacity(0.1),
          ),
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isInside ? Colors.green : Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: (isInside ? Colors.green : Colors.red)
                        .withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // الحالة
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isInside ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            isInside ? '✓ Safe Zone' : '⚠ Outside Zone',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // معلومات الموقع
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.teal[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.location_on, color: Colors.teal[600]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          location.address ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Last updated: ${_formatTime(location.timestamp)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // زر Get Directions
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _openDirections(location),
            icon: const Icon(Icons.directions),
            label: const Text('Get Directions to Patient'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// تبويب Safe Zones
  Widget _buildSafeZonesTab(BuildContext context, FamilyTrackingState state) {
    return Column(
      children: [
        // قائمة Safe Zones
        if (state.safeZones.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('لم يتم إنشاء مناطق آمنة'),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.safeZones.length,
            itemBuilder: (context, index) {
              final zone = state.safeZones[index];
              return _buildSafeZoneCard(context, zone);
            },
          ),
        const SizedBox(height: 16),

        // زر Add New Safe Zone
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _showAddSafeZoneDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add New Safe Zone'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// بطاقة Safe Zone
  Widget _buildSafeZoneCard(BuildContext context, SafeZone zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.teal[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.shield, color: Colors.teal[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  zone.address ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Radius: ${formatDistance(zone.radiusMeters)}',
                  style: TextStyle(
                    color: Colors.teal[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Toggle Active
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: zone.isActive,
              onChanged: (value) {
                context.read<FamilyTrackingCubit>().toggleSafeZone(
                  zone.id,
                  value,
                );
              },
              activeColor: Colors.teal,
            ),
          ),
          // Delete Button
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red[400]),
            onPressed: () {
              context.read<FamilyTrackingCubit>().deleteSafeZone(zone.id);
            },
          ),
        ],
      ),
    );
  }

  /// تبويب History
  Widget _buildHistoryTab(BuildContext context, FamilyTrackingState state) {
    if (state.locationHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('لا توجد سجلات'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Places visited recently',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.locationHistory.length,
          itemBuilder: (context, index) {
            final history = state.locationHistory[index];
            return _buildHistoryCard(context, history);
          },
        ),
      ],
    );
  }

  /// بطاقة السجل
  Widget _buildHistoryCard(BuildContext context, LocationHistory history) {
    final isCurrent = history.departedAt == null;
    final duration = history.durationMinutes;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            history.placeName ?? 'Unknown Location',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            history.address ?? '',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(history.arrivedAt),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '● Current location',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Text(
                  '⏱ ${duration ?? 0} minutes',
                  style: TextStyle(
                    color: Colors.teal[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openDirections(
                PatientLocation(
                  id: 'history-${history.id}',
                  patientId: history.patientId,
                  latitude: history.latitude,
                  longitude: history.longitude,
                  address: history.address,
                  accuracy: 0,
                  timestamp: history.arrivedAt,
                ),
              ),
              icon: const Icon(Icons.directions, size: 16),
              label: const Text('Directions'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal,
                side: const BorderSide(color: Colors.teal),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// فتح الاتجاهات
  Future<void> _openDirections(PatientLocation location) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}',
    );
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// فتح dialog إضافة منطقة آمنة
  void _showAddSafeZoneDialog(BuildContext context) {
    final cubit = context.read<FamilyTrackingCubit>();
    showDialog(
      context: context,
      builder: (context) => AddSafeZoneDialog(
        patientId: cubit.patientId,
        trackingRepository: getIt<TrackingRepository>(),
      ),
    );
  }

  /// تنسيق الوقت
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
