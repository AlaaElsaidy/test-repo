import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // still used elsewhere
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';

class DoctorTrackingScreen extends StatefulWidget {
  const DoctorTrackingScreen({super.key});

  @override
  State<DoctorTrackingScreen> createState() => _DoctorTrackingScreenState();
}

class _DoctorTrackingScreenState extends State<DoctorTrackingScreen> {
  int _selectedIndex = 0;

  // Dummy patients data (editable later)
  late final List<_Patient> _patients = [
    _Patient(
      name: 'Margaret Smith',
      locationLabel: 'At Home',
      position: const _LatLng(37.3318, -122.0312),
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
      safeZones: [
        _SafeZone(
          name: 'Home',
          address: '123 Oak Street, Springfield',
          lat: 37.3318,
          lng: -122.0312,
          radiusMeters: 200,
          isActive: true,
        ),
        _SafeZone(
          name: 'Park',
          address: 'Central Park, Springfield',
          lat: 37.3333,
          lng: -122.0293,
          radiusMeters: 150,
          isActive: true,
        ),
        _SafeZone(
          name: 'Hospital',
          address: 'Springfield General Hospital',
          lat: 37.3270,
          lng: -122.0305,
          radiusMeters: 100,
          isActive: false,
        ),
      ],
      history: [
        _HistoryEntry(
          place: 'Home',
          address: '123 Oak Street, Springfield',
          timeLabel: '2 mins ago',
          durationLabel: 'Current location',
          icon: Icons.home,
          color: Colors.green,
          lat: 37.3318,
          lng: -122.0312,
        ),
        _HistoryEntry(
          place: 'Park',
          address: 'Central Park, Springfield',
          timeLabel: '2 hours ago',
          durationLabel: '45 minutes',
          icon: Icons.park,
          color: AppTheme.teal500,
          lat: 37.3333,
          lng: -122.0293,
        ),
      ],
    ),
    _Patient(
      name: 'John Davis',
      locationLabel: 'Park',
      position: const _LatLng(37.3330, -122.0290),
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
      safeZones: [
        _SafeZone(
          name: 'Home',
          address: '45 Pine Street, Springfield',
          lat: 37.3300,
          lng: -122.0325,
          radiusMeters: 180,
          isActive: true,
        ),
        _SafeZone(
          name: 'Park',
          address: 'Central Park, Springfield',
          lat: 37.3333,
          lng: -122.0293,
          radiusMeters: 150,
          isActive: true,
        ),
      ],
      history: [
        _HistoryEntry(
          place: 'Park',
          address: 'Central Park, Springfield',
          timeLabel: '5 mins ago',
          durationLabel: '20 minutes',
          icon: Icons.park,
          color: AppTheme.teal500,
          lat: 37.3333,
          lng: -122.0293,
        ),
        _HistoryEntry(
          place: 'Home',
          address: '45 Pine Street, Springfield',
          timeLabel: 'Yesterday',
          durationLabel: '3 hours',
          icon: Icons.home,
          color: Colors.green,
          lat: 37.3300,
          lng: -122.0325,
        ),
      ],
    ),
    _Patient(
      name: 'Mary Taylor',
      locationLabel: 'Outside Safe Zone',
      position: const _LatLng(37.3365, -122.0400),
      lastUpdated: DateTime.now(),
      safeZones: [
        _SafeZone(
          name: 'Home',
          address: '15 Maple Ave, Springfield',
          lat: 37.3315,
          lng: -122.0318,
          radiusMeters: 120,
          isActive: true,
        ),
        _SafeZone(
          name: 'Church',
          address: 'Community Church',
          lat: 37.3345,
          lng: -122.0350,
          radiusMeters: 100,
          isActive: false,
        ),
      ],
      history: [
        _HistoryEntry(
          place: 'Home',
          address: '15 Maple Ave, Springfield',
          timeLabel: 'Yesterday',
          durationLabel: '2 hours',
          icon: Icons.home,
          color: Colors.green,
          lat: 37.3315,
          lng: -122.0318,
        ),
      ],
    ),
  ];

  // ===== Utils =====

  // Haversine distance (meters)
  double _distanceMeters(_LatLng a, _LatLng b) {
    const r = 6371000.0;
    final dLat = _deg2rad(b.lat - a.lat);
    final dLng = _deg2rad(b.lng - a.lng);
    final aa = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(a.lat)) *
            cos(_deg2rad(b.lat)) *
            (sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(aa), sqrt(1 - aa));
    return r * c;
  }

  double _deg2rad(double d) => d * pi / 180.0;

  bool _isInsideZone(_LatLng pos, _SafeZone z) {
    if (!z.isActive) return false;
    final d = _distanceMeters(pos, _LatLng(z.lat, z.lng));
    return d <= z.radiusMeters;
  }

  bool _isSafe(_Patient p) =>
      p.safeZones.any((z) => _isInsideZone(p.position, z));

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60)
      return '${d.inMinutes} min${d.inMinutes > 1 ? 's' : ''} ago';
    if (d.inHours < 24)
      return '${d.inHours} hour${d.inHours > 1 ? 's' : ''} ago';
    return '${d.inDays} day${d.inDays > 1 ? 's' : ''} ago';
  }

  void _refreshSelected() {
    final r = Random();
    final p = _patients[_selectedIndex];
    final deltaLat = (r.nextDouble() - 0.5) / 5000;
    final deltaLng = (r.nextDouble() - 0.5) / 5000;
    setState(() {
      _patients[_selectedIndex] = p.copyWith(
        position: _LatLng(p.position.lat + deltaLat, p.position.lng + deltaLng),
        lastUpdated: DateTime.now(),
      );
    });
  }

  Future<void> _openMapsTo({
    required double lat,
    required double lng,
    String? label,
  }) async {
    final String qLabel = label ?? 'Patient';
    final encodedLabel = Uri.encodeComponent(qLabel);
    final Uri appleMaps =
        Uri.parse('http://maps.apple.com/?ll=$lat,$lng&q=$encodedLabel');
    final Uri androidGeo =
        Uri.parse('geo:$lat,$lng?q=$lat,$lng($encodedLabel)');
    final Uri googleWeb =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.iOS) {
      if (await canLaunchUrl(appleMaps)) {
        await launchUrl(appleMaps, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(googleWeb, mode: LaunchMode.externalApplication);
      return;
    } else if (platform == TargetPlatform.android) {
      if (await canLaunchUrl(androidGeo)) {
        await launchUrl(androidGeo, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(googleWeb, mode: LaunchMode.externalApplication);
      return;
    }
    await launchUrl(googleWeb, mode: LaunchMode.externalApplication);
  }

  // Get current device location (doctor device)
  Future<_LatLng?> _getMyCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable Location Services')),
          );
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      return _LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get current location: $e')),
        );
      }
      return null;
    }
  }

  void _openHistorySheet(_Patient p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, controller) {
            final bottomPad = MediaQuery.of(context).padding.bottom + 16;
            return SafeArea(
              top: false,
              child: ListView.separated(
                controller: controller,
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                itemCount: p.history.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Text(
                      'Location History • ${p.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.teal900,
                      ),
                    );
                  }
                  final e = p.history[i - 1];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: e.color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(e.icon, color: e.color),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.place,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.teal900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      e.address,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.gray600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time,
                                            size: 14, color: AppTheme.gray500),
                                        const SizedBox(width: 4),
                                        Text(
                                          e.timeLabel,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.gray500,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(Icons.timelapse,
                                            size: 14, color: e.color),
                                        const SizedBox(width: 4),
                                        Text(
                                          e.durationLabel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: e.color,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: () => _openMapsTo(
                                lat: e.lat,
                                lng: e.lng,
                                label: e.place,
                              ),
                              icon: const Icon(Icons.directions, size: 18),
                              label: const Text('Directions'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.teal600,
                                side: const BorderSide(color: AppTheme.teal500),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // Read-only Safe Zones sheet (view only)
  void _openSafeZonesViewerSheet(_Patient p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, controller) {
            final zones = p.safeZones;
            final bottomPad = MediaQuery.of(context).padding.bottom + 16;

            return SafeArea(
              top: false,
              child: ListView.builder(
                controller: controller,
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                itemCount: zones.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Safe Zones • ${p.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.teal900,
                        ),
                      ),
                    );
                  }
                  final z = zones[i - 1];
                  final inside = _isInsideZone(p.position, z);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SafeZoneViewCard(
                      name: z.name,
                      address: z.address,
                      radius: '${z.radiusMeters.toInt()}m',
                      isActive: z.isActive,
                      isInside: inside,
                      onDirections: () => _openMapsTo(
                        lat: z.lat,
                        lng: z.lng,
                        label: z.name,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // Note: Keeping original editor methods in case you need them later, but we won't use them now.
  void _openSafeZonesSheet(_Patient p) {
    /* unused editor - left intact */
  }

  void _openAddSafeZoneSheet(
      {required _Patient patient, required void Function(_SafeZone) onAdd}) {
    /* unused */
  }

  @override
  Widget build(BuildContext context) {
    final p = _patients[_selectedIndex];
    final isSafe = _isSafe(p);
    final statusText = isSafe ? 'Safe Zone' : 'Alert';
    final statusColor = isSafe ? Colors.green : Colors.red;

    return SafeArea(
      child: Column(
        children: [
          // Header + patient selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(gradient: AppTheme.tealGradient),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Live Tracking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.settings),
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedIndex,
                      isExpanded: true,
                      dropdownColor: AppTheme.teal600,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.white),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      items: List.generate(_patients.length, (i) {
                        final pp = _patients[i];
                        final safe = _isSafe(pp);
                        return DropdownMenuItem<int>(
                          value: i,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: safe ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(pp.name),
                            ],
                          ),
                        );
                      }),
                      onChanged: (i) {
                        if (i == null) return;
                        setState(() => _selectedIndex = i);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Map area (responsive illustration)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.teal100, AppTheme.cyan100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  final ring = (w < h ? w : h) * 0.68; // 68% of min side
                  final pin = (ring * 0.28).clamp(36.0, 80.0);
                  final borderW = (ring * 0.015).clamp(2.0, 6.0);

                  return Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: ring,
                          height: ring,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                              width: borderW,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: pin,
                          height: pin,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.6),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person_pin_circle,
                            color: Colors.white,
                            size: pin * 0.5,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                statusText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Info panel + actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.teal50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.location_on,
                          color: AppTheme.teal600),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.teal900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.locationLabel,
                            style: const TextStyle(
                                fontSize: 14, color: AppTheme.gray600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last updated: ${_timeAgo(p.lastUpdated)}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.gray500),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _refreshSelected,
                      icon: const Icon(Icons.refresh),
                      color: AppTheme.teal600,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openMapsTo(
                          lat: p.position.lat,
                          lng: p.position.lng,
                          label: '${p.name} location',
                        ),
                        icon: const Icon(Icons.directions),
                        label: const Text('Get Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.teal500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openHistorySheet(p),
                        icon: const Icon(Icons.history),
                        label: const Text('History'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cyan500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openSafeZonesViewerSheet(p), // VIEW ONLY
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('Safe Zones'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.teal600,
                      side: const BorderSide(color: AppTheme.teal500),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Models =====
class _LatLng {
  final double lat;
  final double lng;
  const _LatLng(this.lat, this.lng);
}

class _SafeZone {
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double radiusMeters;
  final bool isActive;

  const _SafeZone({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
    required this.isActive,
  });

  _SafeZone copyWith({bool? isActive}) => _SafeZone(
        name: name,
        address: address,
        lat: lat,
        lng: lng,
        radiusMeters: radiusMeters,
        isActive: isActive ?? this.isActive,
      );
}

class _HistoryEntry {
  final String place;
  final String address;
  final String timeLabel;
  final String durationLabel;
  final IconData icon;
  final Color color;
  final double lat;
  final double lng;

  const _HistoryEntry({
    required this.place,
    required this.address,
    required this.timeLabel,
    required this.durationLabel,
    required this.icon,
    required this.color,
    required this.lat,
    required this.lng,
  });
}

class _Patient {
  final String name;
  final String locationLabel;
  final _LatLng position;
  final DateTime lastUpdated;
  final List<_SafeZone> safeZones;
  final List<_HistoryEntry> history;

  _Patient({
    required this.name,
    required this.locationLabel,
    required this.position,
    required this.lastUpdated,
    required this.safeZones,
    required this.history,
  });

  _Patient copyWith({
    String? name,
    String? locationLabel,
    _LatLng? position,
    DateTime? lastUpdated,
    List<_SafeZone>? safeZones,
    List<_HistoryEntry>? history,
  }) {
    return _Patient(
      name: name ?? this.name,
      locationLabel: locationLabel ?? this.locationLabel,
      position: position ?? this.position,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      safeZones: safeZones ?? this.safeZones,
      history: history ?? this.history,
    );
  }
}

// ===== UI helpers =====

// Read-only Safe Zone card (no toggle/delete)
class _SafeZoneViewCard extends StatelessWidget {
  final String name;
  final String address;
  final String radius;
  final bool isActive;
  final bool isInside;
  final VoidCallback onDirections;

  const _SafeZoneViewCard({
    required this.name,
    required this.address,
    required this.radius,
    required this.isActive,
    required this.isInside,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isInside
                        ? Colors.green.withOpacity(0.2)
                        : isActive
                            ? AppTheme.teal50
                            : AppTheme.gray100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isInside
                        ? Icons.check_circle
                        : isActive
                            ? Icons.shield
                            : Icons.shield_outlined,
                    color: isInside
                        ? Colors.green
                        : isActive
                            ? AppTheme.teal500
                            : AppTheme.gray500,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.teal900,
                              ),
                            ),
                          ),
                          if (isInside)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Inside',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (!isActive)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.gray100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Disabled',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.gray600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.gray600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Radius: $radius',
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? AppTheme.teal600 : AppTheme.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onDirections,
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Directions'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.teal600,
                  side: const BorderSide(color: AppTheme.teal500),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Kept from previous editor (not used now), in case you re-enable editing later.
class _SafeZoneCardRow extends StatelessWidget {
  final String name;
  final String address;
  final String radius;
  final bool isActive;
  final bool isInside;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onDelete;

  const _SafeZoneCardRow({
    required this.name,
    required this.address,
    required this.radius,
    required this.isActive,
    required this.isInside,
    required this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.teal50 : AppTheme.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isInside
                  ? Colors.green.withOpacity(0.2)
                  : isActive
                      ? AppTheme.teal50
                      : AppTheme.gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isInside
                  ? Icons.check_circle
                  : isActive
                      ? Icons.shield
                      : Icons.shield_outlined,
              color: isInside
                  ? Colors.green
                  : isActive
                      ? AppTheme.teal500
                      : AppTheme.gray500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.teal900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(fontSize: 12, color: AppTheme.gray600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Radius: $radius',
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? AppTheme.teal600 : AppTheme.gray500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: isActive,
                onChanged: onToggle,
                activeColor: AppTheme.teal500,
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}