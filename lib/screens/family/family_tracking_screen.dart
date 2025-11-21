import 'dart:math';

import 'package:alzcare/core/shared-prefrences/shared-prefrences-helper.dart';
import 'package:alzcare/core/supabase/patient-family-service.dart';
import 'package:alzcare/core/supabase/tracking-service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';

class FamilyTrackingScreen extends StatefulWidget {
  const FamilyTrackingScreen({super.key});

  @override
  State<FamilyTrackingScreen> createState() => _FamilyTrackingScreenState();
}

class _FamilyTrackingScreenState extends State<FamilyTrackingScreen> {
  int _selectedTab = 0; // 0: Live, 1: Safe Zones (Editor), 2: History

  String _patientName = 'Loading...';
  String? _patientRecordId;
  bool _loading = false;

  final TrackingService _trackingService = TrackingService();
  final PatientFamilyService _patientFamilyService = PatientFamilyService();

  // Patient location
  _LatLng? _patient;
  DateTime? _lastUpdated;
  String? _patientAddress;

  // Safe zones data
  List<Map<String, dynamic>> _safeZones = [];

  // History data
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() => _loading = true);
    try {
      final familyUid = SharedPrefsHelper.getString('familyUid') ??
          SharedPrefsHelper.getString('userId');
      if (familyUid == null) {
        setState(() {
          _loading = false;
          _patientName = 'No patient linked';
        });
        return;
      }

      // Get first patient linked to this family member
      final patients = await _patientFamilyService.getPatientsByFamily(familyUid);
      if (patients.isEmpty) {
        setState(() {
          _loading = false;
          _patientName = 'No patient linked';
        });
        return;
      }

      final patientData = patients.first;
      final patient = patientData['patients'] as Map<String, dynamic>?;
      if (patient == null) {
        setState(() {
          _loading = false;
          _patientName = 'No patient linked';
        });
        return;
      }

      _patientRecordId = patient['id'] as String;
      _patientName = patient['name'] as String? ?? 'Unknown Patient';

      // Load location, safe zones, and history
      await Future.wait([
        _loadPatientLocation(),
        _loadSafeZones(),
        _loadHistory(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load patient data: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadPatientLocation() async {
    if (_patientRecordId == null) return;

    try {
      final location = await _trackingService
          .getPatientCurrentLocationByRecordId(_patientRecordId!);
      if (location != null && mounted) {
        setState(() {
          _patient = _LatLng(
            (location['latitude'] as num).toDouble(),
            (location['longitude'] as num).toDouble(),
          );
          _patientAddress = location['address'] as String?;
          final updatedAt = location['updated_at'] as String?;
          if (updatedAt != null) {
            _lastUpdated = DateTime.parse(updatedAt);
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load patient location: $e');
    }
  }

  Future<void> _loadSafeZones() async {
    if (_patientRecordId == null) return;

    try {
      final zones = await _trackingService
          .getSafeZonesForPatientByRecordId(_patientRecordId!);
      setState(() => _safeZones = zones);
    } catch (e) {
      debugPrint('Failed to load safe zones: $e');
    }
  }

  Future<void> _loadHistory() async {
    if (_patientRecordId == null) return;

    try {
      final history = await _trackingService
          .getLocationHistoryByRecordId(_patientRecordId!, limit: 50);
      setState(() => _history = history);
    } catch (e) {
      debugPrint('Failed to load history: $e');
    }
  }

  // Distance in meters using Haversine
  double _distanceMeters(_LatLng a, _LatLng b) {
    const earthRadius = 6371000.0; // meters
    final dLat = _deg2rad(b.lat - a.lat);
    final dLng = _deg2rad(b.lng - a.lng);
    final aa = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(a.lat)) * cos(_deg2rad(b.lat)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(aa), sqrt(1 - aa));
    return earthRadius * c;
  }

  double _deg2rad(double deg) => deg * pi / 180.0;

  bool _isInsideZone(Map<String, dynamic> zone) {
    if (zone['is_active'] != true || _patient == null) return false;
    final d = _distanceMeters(
      _patient!,
      _LatLng(
        (zone['latitude'] as num).toDouble(),
        (zone['longitude'] as num).toDouble(),
      ),
    );
    return d <= (zone['radius_meters'] as num).toDouble();
  }

  bool get _isInsideAnyActiveZone {
    if (_patient == null) return false;
    return _safeZones.any(_isInsideZone);
  }

  String _timeAgo(DateTime? t) {
    if (t == null) return '—';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min${d.inMinutes > 1 ? 's' : ''} ago';
    if (d.inHours < 24) return '${d.inHours} hour${d.inHours > 1 ? 's' : ''} ago';
    return '${d.inDays} day${d.inDays > 1 ? 's' : ''} ago';
  }

  Future<void> _refreshLocation() async {
    await _loadPatientLocation();
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

  // Get current device location (for "Use my current location")
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

  // Add Safe Zone sheet (like Doctor screen)
  void _openAddSafeZoneSheet() {
    if (_patientRecordId == null || _patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient data not loaded')),
      );
      return;
    }

    final nameCtrl = TextEditingController(text: 'New Zone');
    final addrCtrl = TextEditingController(text: '');
    final latCtrl =
        TextEditingController(text: _patient!.lat.toStringAsFixed(6));
    final lngCtrl =
        TextEditingController(text: _patient!.lng.toStringAsFixed(6));
    double radius = 150;
    bool isActive = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void useCoords(double lat, double lng,
                {String? name, String? address}) {
              latCtrl.text = lat.toStringAsFixed(6);
              lngCtrl.text = lng.toStringAsFixed(6);
              if (name != null) nameCtrl.text = name;
              if (address != null) addrCtrl.text = address;
              setSheetState(() {});
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Safe Zone',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.teal900,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Suggestions (chips)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_patient != null)
                            ActionChip(
                              label: const Text('Use patient location'),
                              avatar:
                                  const Icon(Icons.person_pin_circle, size: 18),
                              onPressed: () => useCoords(
                                _patient!.lat,
                                _patient!.lng,
                                name: 'Patient Location',
                              ),
                            ),
                          ActionChip(
                            label: const Text('Use my current location'),
                            avatar: const Icon(Icons.my_location, size: 18),
                            onPressed: () async {
                              final here = await _getMyCurrentLocation();
                              if (here != null) {
                                useCoords(here.lat, here.lng,
                                    name: 'My Current Location');
                              }
                            },
                          ),
                          ..._history.take(3).map((h) {
                            final placeName = h['place_name'] as String? ?? 'Unknown';
                            final address = h['address'] as String? ?? '';
                            final lat = (h['latitude'] as num).toDouble();
                            final lng = (h['longitude'] as num).toDouble();
                            return ActionChip(
                              label: Text(placeName),
                              avatar: const Icon(Icons.place, size: 18),
                              onPressed: () => useCoords(lat, lng,
                                  name: placeName, address: address),
                            );
                          }),
                        ],
                      ),

                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'Name',
                        child: TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Home, Park, Clinic',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        label: 'Address',
                        child: TextField(
                          controller: addrCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Optional address/description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: 'Latitude',
                              child: TextField(
                                controller: latCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: true,
                                ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabeledField(
                              label: 'Longitude',
                              child: TextField(
                                controller: lngCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: true,
                                ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _LabeledField(
                        label: 'Radius: ${radius.toInt()} m',
                        child: Slider(
                          min: 50,
                          max: 500,
                          divisions: 18,
                          value: radius,
                          activeColor: AppTheme.teal500,
                          onChanged: (v) => setSheetState(() => radius = v),
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Switch(
                                value: isActive,
                                onChanged: (v) =>
                                    setSheetState(() => isActive = v),
                                activeColor: AppTheme.teal500,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Active',
                                style: TextStyle(
                                  color: AppTheme.teal900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              final lat = double.tryParse(latCtrl.text);
                              final lng = double.tryParse(lngCtrl.text);
                              if (lat == null || lng == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Enter valid lat/lng first')),
                                );
                                return;
                              }
                              _openMapsTo(
                                lat: lat,
                                lng: lng,
                                label: nameCtrl.text.isEmpty
                                    ? 'Safe Zone'
                                    : nameCtrl.text,
                              );
                            },
                            icon: const Icon(Icons.map),
                            label: const Text('Preview in Maps'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final name = nameCtrl.text.trim().isEmpty
                                ? 'New Zone'
                                : nameCtrl.text.trim();
                            final address = addrCtrl.text.trim();
                            final lat = double.tryParse(latCtrl.text);
                            final lng = double.tryParse(lngCtrl.text);
                            if (lat == null || lng == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Please enter valid coordinates')),
                              );
                              return;
                            }

                            try {
                              final familyUid = SharedPrefsHelper.getString('familyUid') ??
                                  SharedPrefsHelper.getString('userId');
                              
                              await _trackingService.createSafeZone(
                                patientId: _patientRecordId!,
                                familyMemberId: familyUid,
                                name: name,
                                address: address.isEmpty ? null : address,
                                latitude: lat,
                                longitude: lng,
                                radiusMeters: radius,
                                isActive: isActive,
                                isPatientRecordId: true,
                              );

                              await _loadSafeZones();
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Safe zone added')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to add safe zone: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Save Safe Zone'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.teal500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: AppTheme.tealGradient,
            ),
            child: Column(
              children: [
                Row(
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _patientName,
                            style: const TextStyle(
                              color: Color(0xFFCFFAFE),
                              fontSize: 14,
                            ),
                          ),
                        ],
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

                // Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Live',
                          icon: Icons.location_on,
                          isSelected: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: 'Safe Zones',
                          icon: Icons.shield,
                          isSelected: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1),
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: 'History',
                          icon: Icons.history,
                          isSelected: _selectedTab == 2,
                          onTap: () => setState(() => _selectedTab = 2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 0
                    ? _patient == null
                        ? const Center(child: Text('No location data available'))
                        : _LiveTrackingView(
                            isInsideAny: _isInsideAnyActiveZone,
                            statusText: _isInsideAnyActiveZone
                                ? 'Safe Zone'
                                : 'Outside Zone',
                            statusColor: _isInsideAnyActiveZone
                                ? Colors.green
                                : Colors.red,
                            address: _patientAddress ??
                                '${_patient!.lat.toStringAsFixed(5)}, ${_patient!.lng.toStringAsFixed(5)}',
                            lastUpdatedLabel: _timeAgo(_lastUpdated),
                            onRefresh: _refreshLocation,
                            onDirections: () => _openMapsTo(
                              lat: _patient!.lat,
                              lng: _patient!.lng,
                              label: '$_patientName location',
                            ),
                          )
                    : _selectedTab == 1
                        // Editor directly (like Doctor screen)
                        ? _SafeZonesEditorView(
                            patientName: _patientName,
                            zones: _safeZones,
                            isInside: _isInsideZone,
                            onToggle: (i, val) async {
                              try {
                                final zoneId = _safeZones[i]['id'] as String;
                                await _trackingService.updateSafeZone(
                                  zoneId,
                                  {'is_active': val},
                                );
                                await _loadSafeZones();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Failed to update: $e')),
                                  );
                                }
                              }
                            },
                            onDelete: (i) async {
                              final z = _safeZones[i];
                              final zoneName = z['name'] as String? ?? 'Unknown';
                              final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Delete Safe Zone'),
                                      content: Text(
                                          'Are you sure you want to delete "$zoneName"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                              if (confirmed) {
                                try {
                                  final zoneId = _safeZones[i]['id'] as String;
                                  await _trackingService.deleteSafeZone(zoneId);
                                  await _loadSafeZones();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Failed to delete: $e')),
                                    );
                                  }
                                }
                              }
                            },
                            onAddPressed: _openAddSafeZoneSheet,
                          )
                        : _HistoryView(
                            entries: _history,
                            onOpenMap: (lat, lng, label) =>
                                _openMapsTo(lat: lat, lng: lng, label: label),
                          ),
          ),
        ],
      ),
    );
  }
}

// Models
class _LatLng {
  final double lat;
  final double lng;
  const _LatLng(this.lat, this.lng);
}


// UI widgets
class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.teal600 : Colors.white,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppTheme.teal600 : Colors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveTrackingView extends StatelessWidget {
  final bool isInsideAny;
  final String statusText;
  final Color statusColor;
  final String address;
  final String lastUpdatedLabel;
  final VoidCallback onRefresh;
  final VoidCallback onDirections;

  const _LiveTrackingView({
    required this.isInsideAny,
    required this.statusText,
    required this.statusColor,
    required this.address,
    required this.lastUpdatedLabel,
    required this.onRefresh,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map Area (illustration)
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.teal100, AppTheme.cyan100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Illustration
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 3,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 64,
                        height: 64,
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
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            ),
          ),
        ),

        // Info Panel
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
                      color: (isInsideAny ? Colors.green[100] : Colors.red[100]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: isInsideAny ? Colors.green[600] : Colors.red[600],
                    ),
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
                          address,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.gray600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last updated: $lastUpdatedLabel',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    color: AppTheme.teal600,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions),
                  label: const Text('Get Directions to Patient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.teal500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Editor view (like Doctor screen)
class _SafeZonesEditorView extends StatelessWidget {
  final String patientName;
  final List<Map<String, dynamic>> zones;
  final bool Function(Map<String, dynamic>) isInside;
  final void Function(int index, bool value) onToggle;
  final void Function(int index) onDelete;
  final VoidCallback onAddPressed;

  const _SafeZonesEditorView({
    required this.patientName,
    required this.zones,
    required this.isInside,
    required this.onToggle,
    required this.onDelete,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.lightGradient),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Safe Zones • $patientName',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.teal900,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(zones.length, (i) {
            final z = zones[i];
            final inside = isInside(z);
            final name = z['name'] as String? ?? 'Unknown';
            final address = z['address'] as String? ?? '';
            final radius = (z['radius_meters'] as num?)?.toInt() ?? 0;
            final isActive = z['is_active'] == true;
            return Padding(
              padding: EdgeInsets.only(bottom: i == zones.length - 1 ? 0 : 12),
              child: _SafeZoneCardRow(
                name: name,
                address: address,
                radius: '${radius}m',
                isActive: isActive,
                isInside: inside,
                onToggle: (val) => onToggle(i, val),
                onDelete: () => onDelete(i),
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add),
              label: const Text('Add New Safe Zone'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// History view and item
class _HistoryView extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final void Function(double lat, double lng, String label) onOpenMap;

  const _HistoryView({
    required this.entries,
    required this.onOpenMap,
  });

  String _timeAgo(DateTime? t) {
    if (t == null) return '—';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min${d.inMinutes > 1 ? 's' : ''} ago';
    if (d.inHours < 24) return '${d.inHours} hour${d.inHours > 1 ? 's' : ''} ago';
    return '${d.inDays} day${d.inDays > 1 ? 's' : ''} ago';
  }

  IconData _getIconForPlace(String? placeName) {
    if (placeName == null) return Icons.place;
    final lower = placeName.toLowerCase();
    if (lower.contains('home')) return Icons.home;
    if (lower.contains('park')) return Icons.park;
    if (lower.contains('hospital') || lower.contains('clinic')) return Icons.local_hospital;
    if (lower.contains('shop') || lower.contains('mall')) return Icons.shopping_bag;
    return Icons.place;
  }

  Color _getColorForPlace(String? placeName) {
    if (placeName == null) return AppTheme.teal500;
    final lower = placeName.toLowerCase();
    if (lower.contains('home')) return Colors.green;
    if (lower.contains('park')) return AppTheme.teal500;
    if (lower.contains('hospital') || lower.contains('clinic')) return Colors.red;
    if (lower.contains('shop') || lower.contains('mall')) return AppTheme.cyan500;
    return AppTheme.teal500;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.lightGradient),
      child: entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No location history available',
                  style: TextStyle(color: AppTheme.gray600),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Location History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.teal900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Places visited recently',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.gray600,
                  ),
                ),
                const SizedBox(height: 16),
                ...entries.map((e) {
                  final placeName = e['place_name'] as String? ?? 'Unknown';
                  final address = e['address'] as String? ?? '';
                  final lat = (e['latitude'] as num).toDouble();
                  final lng = (e['longitude'] as num).toDouble();
                  final arrivedAt = e['arrived_at'] as String?;
                  final duration = e['duration_minutes'] as int?;
                  final arrived = arrivedAt != null
                      ? DateTime.tryParse(arrivedAt)
                      : null;
                  final timeLabel = _timeAgo(arrived);
                  final durationLabel = duration != null
                      ? duration < 60
                          ? '$duration min${duration > 1 ? 's' : ''}'
                          : '${(duration / 60).toStringAsFixed(1)} hour${(duration / 60) > 1 ? 's' : ''}'
                      : '—';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HistoryItem(
                      place: placeName,
                      address: address,
                      time: timeLabel,
                      duration: durationLabel,
                      icon: _getIconForPlace(placeName),
                      color: _getColorForPlace(placeName),
                      onDirections: () => onOpenMap(lat, lng, placeName),
                    ),
                  );
                }),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String place;
  final String address;
  final String time;
  final String duration;
  final IconData icon;
  final Color color;
  final VoidCallback onDirections;

  const _HistoryItem({
    required this.place,
    required this.address,
    required this.time,
    required this.duration,
    required this.icon,
    required this.color,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.teal900,
                        ),
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: AppTheme.gray500),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.gray500),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.timelapse, size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(
                            duration,
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
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

// ===== UI helpers for editor (same as Doctor) =====
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

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.gray600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}