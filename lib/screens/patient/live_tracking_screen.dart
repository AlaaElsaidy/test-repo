import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/shared-prefrences/shared-prefrences-helper.dart';
import '../../core/supabase/location-tracking-service.dart';
import '../../core/supabase/safe-zone-service.dart';
import '../../core/supabase/supabase-service.dart';
import '../../theme/app_theme.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  bool _loading = false;
  Position? _pos;
  DateTime? _lastUpdated;
  String? _address;
  String? _emergencyPhone;
  String? _patientId;

  final LocationTrackingService _locationService = LocationTrackingService();
  final SafeZoneService _safeZoneService = SafeZoneService();
  final PatientService _patientService = PatientService();

  // Safe Zones from database
  List<SafeZone> _safeZones = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final userId = SharedPrefsHelper.getString("userId") ?? 
                   SharedPrefsHelper.getString("patientUid");
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found')),
        );
      }
      return;
    }

    setState(() => _patientId = userId);

    // Get patient record and emergency phone
    final patient = await _patientService.getPatientByUserId(userId);
    if (patient != null) {
      setState(() {
        _emergencyPhone = patient['phone_emergency'] as String?;
      });
    }

    // Load safe zones
    await _loadSafeZones();

    // Get current location
    _getCurrentLocation();
  }

  Future<void> _loadSafeZones() async {
    if (_patientId == null) return;

    try {
      final zones = await _safeZoneService.getSafeZonesByPatient(_patientId!);
      setState(() {
        _safeZones = zones;
      });
    } catch (e) {
      debugPrint('Failed to load safe zones: $e');
    }
  }

  // Permissions + current location
  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _loading = true);

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable Location Services')),
          );
        }
        await Geolocator.openLocationSettings();
        setState(() => _loading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        setState(() => _loading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // Reverse geocode (optional)
      String? addr;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          addr = [
            if (p.street != null && p.street!.isNotEmpty) p.street,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality,
          ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
        }
      } catch (_) {
        addr = null;
      }

      // Save location to database
      if (_patientId != null) {
        try {
          await _locationService.saveLocation(
            patientId: _patientId!,
            latitude: position.latitude,
            longitude: position.longitude,
            address: addr,
          );
          debugPrint('Location saved successfully to database');
        } catch (e) {
          debugPrint('Failed to save location: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save location: $e'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      setState(() {
        _pos = position;
        _address = addr;
        _lastUpdated = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
      setState(() => _loading = false);
    }
  }

  // Open SMS (Android uses smsto: to avoid WhatsApp prompt)
  Future<void> _openSMS(String phone, String body) async {
    final encoded = Uri.encodeComponent(body);

    final Uri uri = defaultTargetPlatform == TargetPlatform.android
        ? Uri.parse('smsto:$phone?body=$encoded')
        : Uri(scheme: 'sms', path: phone, queryParameters: {'body': body});

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    // fallback to dialer
    await _callNumber(phone);
  }

  // Open WhatsApp (returns true if launched)
  Future<bool> _openWhatsApp(String phoneE164, String text) async {
    // WhatsApp expects digits only (بدون + أو مسافات)
    final phoneDigits = phoneE164.replaceAll(RegExp(r'[^0-9]'), '');
    final encoded = Uri.encodeComponent(text);

    // Try native scheme
    final waUri = Uri.parse('whatsapp://send?phone=$phoneDigits&text=$encoded');
    if (await canLaunchUrl(waUri)) {
      // يفتح واتساب مباشرة لو متثبت
      try {
        await launchUrl(waUri, mode: LaunchMode.externalNonBrowserApplication);
      } catch (_) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      }
      return true;
    }

    // Fallback to wa.me (قد يفتح المتصفح أو يحوّل للواتساب)
    final webUri = Uri.parse('https://wa.me/$phoneDigits?text=$encoded');
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return true;
    }

    return false;
  }

  // Phone call
  Future<void> _callNumber(String phone) async {
    final telUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot place a call on this device')),
        );
      }
    }
  }

  // Emergency: try WhatsApp first; fallback to SMS (then call inside _openSMS if needed)
  Future<void> _sendEmergencyAlert() async {
    if (_emergencyPhone == null || _emergencyPhone!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency contact not configured')),
        );
      }
      return;
    }

    if (_pos == null) {
      await _getCurrentLocation();
    }
    final lat = _pos?.latitude;
    final lng = _pos?.longitude;
    final mapsLink = (lat != null && lng != null)
        ? 'https://www.google.com/maps/?q=$lat,$lng'
        : '';
    final msg = 'EMERGENCY: I feel lost. My current location: $mapsLink';

    bool openedWhatsApp = false;
    try {
      openedWhatsApp = await _openWhatsApp(_emergencyPhone!, msg);
    } catch (_) {
      openedWhatsApp = false;
    }

    if (!openedWhatsApp) {
      await _openSMS(_emergencyPhone!, msg);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(openedWhatsApp
              ? 'Opening WhatsApp...'
              : 'Opening emergency SMS...'),
        ),
      );
    }
  }

  // Helpers
  String _timeAgo(DateTime? t) {
    if (t == null) return '—';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} mins ago';
    if (d.inHours < 24) return '${d.inHours} hours ago';
    return '${d.inDays} days ago';
  }

  double _deg2rad(double d) => d * pi / 180.0;
  double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  bool get _insideAnyZone {
    if (_pos == null) return true; // until first fix, treat as safe
    for (final z in _safeZones) {
      if (!z.isActive) continue;
      final d = _distanceMeters(
        _pos!.latitude,
        _pos!.longitude,
        z.latitude,
        z.longitude,
      );
      if (d <= z.radiusMeters) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _insideAnyZone ? Colors.green : Colors.red;
    final statusText = _insideAnyZone ? 'Safe Zone' : 'Outside Zone';

    final addressText = _address ??
        (_pos == null
            ? 'Fetching location...'
            : '${_pos!.latitude.toStringAsFixed(5)}, ${_pos!.longitude.toStringAsFixed(5)}');

    return SafeArea(
      child: Column(
        children: [
          // Map Container (Responsive to avoid overflow)
          Expanded(
            flex: 2,
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
                  final ring = (w < h ? w : h) * 0.68;
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
                            Icons.location_on,
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

          // Location Info
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _insideAnyZone
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _insideAnyZone ? Icons.shield : Icons.error,
                              color: _insideAnyZone
                                  ? Colors.green[600]
                                  : Colors.red[600],
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
                                  addressText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.gray600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _insideAnyZone
                                      ? 'Within safe zone'
                                      : 'Outside safe zone',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _insideAnyZone
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Last updated + Refresh
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.teal50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: AppTheme.teal600, size: 20),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Last Updated',
                                  style: TextStyle(
                                      fontSize: 14, color: AppTheme.teal900),
                                ),
                                Text(
                                  _timeAgo(_lastUpdated),
                                  style: const TextStyle(
                                      fontSize: 12, color: AppTheme.teal600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _getCurrentLocation,
                          icon: _loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(_loading ? 'Refreshing' : 'Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.teal500,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Emergency Alert
                  Card(
                    color: Colors.orange[50],
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.warning,
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Emergency Alert',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'If you feel lost, tap the button below to notify your caregiver with your current location.',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.orange),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _sendEmergencyAlert,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  child: const Text('Send via WhatsApp/SMS'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: _emergencyPhone != null &&
                                        _emergencyPhone!.isNotEmpty
                                    ? () => _callNumber(_emergencyPhone!)
                                    : null,
                                icon: const Icon(Icons.call),
                                label: const Text('Call'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Note: SafeZone model is now in safe-zone-service.dart