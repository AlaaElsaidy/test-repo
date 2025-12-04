import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/shared-prefrences/shared-prefrences-helper.dart';
import '../../core/supabase/location-tracking-service.dart';
import '../../core/supabase/patient-family-service.dart';
import '../../core/supabase/safe-zone-service.dart';
import '../../theme/app_theme.dart';

class FamilyTrackingScreen extends StatefulWidget {
  const FamilyTrackingScreen({super.key});

  @override
  State<FamilyTrackingScreen> createState() => _FamilyTrackingScreenState();
}

class _FamilyTrackingScreenState extends State<FamilyTrackingScreen> {
  int _selectedTab = 0; // 0: Live, 1: Safe Zones (Editor), 2: History

  // Services
  final LocationTrackingService _locationService = LocationTrackingService();
  final SafeZoneService _safeZoneService = SafeZoneService();
  final PatientFamilyService _patientFamilyService = PatientFamilyService();

  bool get _isAr =>
      (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ar';

  String tr(String en, String ar) => _isAr ? ar : en;

  // Patient data
  String? _patientName;
  String? _selectedPatientUserId;
  String? _selectedPatientRecordId;
  _LatLng? _patient;
  DateTime? _lastUpdated;
  String? _patientAddress;
  bool _loadingLocation = false;

  // Patients list
  List<Map<String, dynamic>> _patients = [];

  // Safe zones data
  List<SafeZone> _safeZones = [];
  bool _loadingZones = false;

  // History data
  List<Map<String, dynamic>> _history = [];
  bool _loadingHistory = false;

  // Map
  GoogleMapController? _mapController;
  CameraPosition _initialCameraPosition =
      const CameraPosition(target: LatLng(24.7136, 46.6753), zoom: 4);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final familyUid = SharedPrefsHelper.getString("familyUid") ??
          SharedPrefsHelper.getString("userId");
      if (familyUid == null) {
        return;
      }

      final patients = await _patientFamilyService.getPatientsByFamily(familyUid);
      // فى التطبيق كل فاميلى مرتبط بمريض واحد فقط، لذلك حتى لو
      // رجعت ليست أكبر من عنصر واحد (بسبب داتا قديمة)، نستخدم
      // أول مريض فقط ونخفى الباقى عن واجهة الفاملى.
      final normalizedPatients =
          patients.isNotEmpty ? <Map<String, dynamic>>[patients.first] : <Map<String, dynamic>>[];

      setState(() {
        _patients = normalizedPatients;
      });

      // Select first patient if available
      if (patients.isNotEmpty) {
        final firstPatient = patients.first['patients'] as Map<String, dynamic>?;
        if (firstPatient != null) {
          final userId = firstPatient['user_id'] as String?;
          final recordId = firstPatient['id'] as String?;
          final name = firstPatient['name'] as String? ?? tr('Patient', 'مريض');
          
          debugPrint('Selecting patient - userId: $userId, recordId: $recordId, name: $name');
          
          if (userId != null && recordId != null) {
            await _selectPatient(userId, recordId, name);
          } else {
            debugPrint('Warning: Patient data incomplete - userId: $userId, recordId: $recordId');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load patients: $e');
    }
  }

  Future<void> _selectPatient(
    String? userId,
    String? recordId,
    String? name,
  ) async {
    if (userId == null || recordId == null) return;

    setState(() {
      _selectedPatientUserId = userId;
      _selectedPatientRecordId = recordId;
      _patientName = name;
      _patient = null;
      _lastUpdated = null;
      _patientAddress = null;
    });

    await Future.wait([
      _loadLocation(),
      _loadSafeZones(),
      _loadHistory(),
    ]);
  }

  Future<void> _loadLocation() async {
    if (_selectedPatientRecordId == null) {
      debugPrint('Cannot load location: _selectedPatientRecordId is null');
      return;
    }

    setState(() => _loadingLocation = true);
    try {
      debugPrint('Loading location for patient record ID: $_selectedPatientRecordId');
      final location = await _locationService
          .getLocationByPatientRecordId(_selectedPatientRecordId!);
      
      if (location != null && location['latitude'] != null) {
        debugPrint('Location loaded: ${location['latitude']}, ${location['longitude']}');
        setState(() {
          _patient = _LatLng(
            location['latitude'] as double,
            location['longitude'] as double,
          );
          _patientAddress = location['address'] as String?;
          if (location['updated_at'] != null) {
            _lastUpdated = DateTime.parse(location['updated_at'] as String);
          } else {
            _lastUpdated = DateTime.now();
          }
          _loadingLocation = false;
          _initialCameraPosition = CameraPosition(
            target: LatLng(_patient!.lat, _patient!.lng),
            zoom: 15,
          );
        });
        _animateMapToPatient();
      } else {
        debugPrint('No location data found for patient');
        setState(() => _loadingLocation = false);
      }
    } catch (e) {
      debugPrint('Failed to load location: $e');
      setState(() => _loadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load location: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadSafeZones() async {
    if (_selectedPatientRecordId == null) return;

    setState(() => _loadingZones = true);
    try {
      final zones = await _safeZoneService
          .getSafeZonesByPatientRecordId(_selectedPatientRecordId!);
      setState(() {
        _safeZones = zones;
        _loadingZones = false;
      });
    } catch (e) {
      debugPrint('Failed to load safe zones: $e');
      setState(() => _loadingZones = false);
    }
  }

  Future<void> _loadHistory() async {
    if (_selectedPatientUserId == null) {
      debugPrint('Cannot load history: _selectedPatientUserId is null');
      return;
    }

    setState(() => _loadingHistory = true);
    try {
      debugPrint('Loading history for patient user ID: $_selectedPatientUserId');
      final history = await _locationService.getLocationHistory(
        patientId: _selectedPatientUserId!,
        limit: 50,
      );
      debugPrint('History loaded: ${history.length} entries');
      setState(() {
        _history = history;
        _loadingHistory = false;
      });
    } catch (e) {
      debugPrint('Failed to load history: $e');
      setState(() => _loadingHistory = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load history: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Note: History is now loaded from database

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

  bool _isInsideZone(SafeZone z) {
    if (!z.isActive || _patient == null) return false;
    final d = _distanceMeters(_patient!, _LatLng(z.latitude, z.longitude));
    return d <= z.radiusMeters;
  }

  bool get _isInsideAnyActiveZone {
    if (_patient == null) return false;
    return _safeZones.any(_isInsideZone);
  }

  Set<Circle> get _safeZoneCircles {
    if (_safeZones.isEmpty) return {};
    return _safeZones.where((z) => z.isActive).map((zone) {
      return Circle(
        circleId: CircleId(zone.id ?? zone.name),
        center: LatLng(zone.latitude, zone.longitude),
        radius: zone.radiusMeters.toDouble(),
        strokeWidth: 2,
        strokeColor: ( _patient != null && _isInsideZone(zone)
                ? Colors.green
                : Colors.red )
            .withOpacity(0.7),
        fillColor: ( _patient != null && _isInsideZone(zone)
                ? Colors.green
                : Colors.red )
            .withOpacity(0.15),
      );
    }).toSet();
  }

  Set<Marker> get _patientMarkers {
    if (_patient == null) return {};
    return {
      Marker(
        markerId: const MarkerId('patient'),
        position: LatLng(_patient!.lat, _patient!.lng),
        infoWindow: InfoWindow(
          title: _patientName ?? 'Patient',
          snippet: _patientAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _isInsideAnyActiveZone
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueRed,
        ),
      ),
    };
  }

  void _animateMapToPatient() {
    if (_mapController == null || _patient == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_patient!.lat, _patient!.lng),
        15,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_patient != null) {
      controller.moveCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_patient!.lat, _patient!.lng),
          15,
        ),
      );
    }
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return tr('Just now', 'الآن');
    if (d.inMinutes < 60) {
      if (_isAr) {
        return 'منذ ${d.inMinutes} دقيقة';
      }
      return '${d.inMinutes} min${d.inMinutes > 1 ? 's' : ''} ago';
    }
    if (d.inHours < 24) {
      if (_isAr) {
        return 'منذ ${d.inHours} ساعة';
      }
      return '${d.inHours} hour${d.inHours > 1 ? 's' : ''} ago';
    }
    if (_isAr) {
      return 'منذ ${d.inDays} يوم';
    }
    return '${d.inDays} day${d.inDays > 1 ? 's' : ''} ago';
  }

  Future<void> _refreshLocation() async {
    await _loadLocation();
  }

  Future<void> _openMapsTo({
    required double lat,
    required double lng,
    String? label,
  }) async {
    final String qLabel = label ?? tr('Patient', 'مريض');
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
            SnackBar(content: Text(tr('Please enable Location Services', 'يرجى تفعيل خدمات الموقع'))),
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
            SnackBar(content: Text(tr('Location permission denied', 'تم رفض إذن الموقع'))),
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
  void _openAddSafeZoneSheet({
    required void Function(_SafeZone) onAdd,
  }) {
    final nameCtrl = TextEditingController(text: tr('New Zone', 'منطقة جديدة'));
    final addrCtrl = TextEditingController(text: '');
    final latCtrl = TextEditingController(
        text: _patient?.lat.toStringAsFixed(6) ?? '0.0');
    final lngCtrl = TextEditingController(
        text: _patient?.lng.toStringAsFixed(6) ?? '0.0');
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
                      Text(
                        tr('Add Safe Zone', 'إضافة منطقة آمنة'),
                        style: const TextStyle(
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
                              label: Text(tr('Use patient location', 'استخدام موقع المريض')),
                              avatar:
                                  const Icon(Icons.person_pin_circle, size: 18),
                              onPressed: () => useCoords(
                                _patient!.lat,
                                _patient!.lng,
                                name: tr('Patient Location', 'موقع المريض'),
                              ),
                            ),
                          ActionChip(
                            label: Text(tr('Use my current location', 'استخدام موقعي الحالي')),
                            avatar: const Icon(Icons.my_location, size: 18),
                            onPressed: () async {
                              final here = await _getMyCurrentLocation();
                              if (here != null) {
                                useCoords(here.lat, here.lng,
                                    name: tr('My Current Location', 'موقعي الحالي'));
                              }
                            },
                          ),
                          ..._history.take(3).map((h) {
                            final lat = h['latitude'] as double?;
                            final lng = h['longitude'] as double?;
                            final address = h['address'] as String?;
                            if (lat == null || lng == null) return const SizedBox();
                            return ActionChip(
                              label: Text(address?.split(',').first ?? tr('Location', 'موقع')),
                              avatar: const Icon(Icons.place, size: 18),
                              onPressed: () => useCoords(lat, lng,
                                  name: address?.split(',').first ?? tr('Location', 'موقع'),
                                  address: address),
                            );
                          }),
                        ],
                      ),

                      const SizedBox(height: 16),
                      _LabeledField(
                        label: tr('Name', 'الاسم'),
                        child: TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            hintText: tr('e.g., Home, Park, Clinic', 'مثال: المنزل، الحديقة، العيادة'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        label: tr('Address', 'العنوان'),
                        child: TextField(
                          controller: addrCtrl,
                          decoration: InputDecoration(
                            hintText: tr('Optional address/description', 'عنوان/وصف اختياري'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: tr('Latitude', 'خط العرض'),
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
                              label: tr('Longitude', 'خط الطول'),
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
                        label: tr('Radius', 'نصف القطر') + ': ${radius.toInt()} ${tr('m', 'م')}',
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
                              Text(
                                tr('Active', 'نشط'),
                                style: const TextStyle(
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
                                  SnackBar(
                                      content:
                                          Text(tr('Enter valid lat/lng first', 'أدخل إحداثيات صحيحة أولاً'))),
                                );
                                return;
                              }
                              _openMapsTo(
                                lat: lat,
                                lng: lng,
                                label: nameCtrl.text.isEmpty
                                    ? tr('Safe Zone', 'منطقة آمنة')
                                    : nameCtrl.text,
                              );
                            },
                            icon: const Icon(Icons.map),
                            label: Text(tr('Preview in Maps', 'معاينة في الخرائط')),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final name = nameCtrl.text.trim().isEmpty
                                ? tr('New Zone', 'منطقة جديدة')
                                : nameCtrl.text.trim();
                            final address = addrCtrl.text.trim();
                            final lat = double.tryParse(latCtrl.text);
                            final lng = double.tryParse(lngCtrl.text);
                            if (lat == null || lng == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(tr('Please enter valid coordinates', 'يرجى إدخال إحداثيات صحيحة'))),
                              );
                              return;
                            }
                            final zone = _SafeZone(
                              name: name,
                              address: address.isEmpty ? '—' : address,
                              lat: lat,
                              lng: lng,
                              radiusMeters: radius,
                              isActive: isActive,
                            );
                            onAdd(zone);
                            Navigator.pop(context); // close add sheet
                          },
                          icon: const Icon(Icons.save),
                          label: Text(tr('Save Safe Zone', 'حفظ المنطقة الآمنة')),
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
                          Text(
                            tr('Live Tracking', 'التتبع المباشر'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _patientName ?? tr('Select Patient', 'اختر مريض'),
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

                // مفيش اختيار بين أكتر من مريض؛ الفاميلى مرتبط بمريض واحد فقط.
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
                          label: tr('Live', 'مباشر'),
                          icon: Icons.location_on,
                          isSelected: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: tr('Safe Zones', 'المناطق الآمنة'),
                          icon: Icons.shield,
                          isSelected: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1),
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: tr('History', 'السجل'),
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
            child: _selectedTab == 0
                ? _patient == null
                    ? Center(
                        child: _loadingLocation
                            ? const CircularProgressIndicator()
                            : Text(tr('No location data available', 'لا توجد بيانات موقع متاحة')),
                      )
                    : _LiveTrackingView(
                        isInsideAny: _isInsideAnyActiveZone,
                        statusText: _isInsideAnyActiveZone
                            ? tr('Safe Zone', 'منطقة آمنة')
                            : tr('Outside Zone', 'خارج المنطقة'),
                        statusColor: _isInsideAnyActiveZone
                            ? Colors.green
                            : Colors.red,
                        address: _patientAddress ??
                            '${_patient!.lat.toStringAsFixed(6)}, ${_patient!.lng.toStringAsFixed(6)}',
                        lastUpdatedLabel: _lastUpdated != null
                            ? _timeAgo(_lastUpdated!)
                            : 'Unknown',
                        onRefresh: _refreshLocation,
                        onDirections: () => _openMapsTo(
                          lat: _patient!.lat,
                          lng: _patient!.lng,
                          label: '${_patientName ?? "Patient"} location',
                        ),
                        mapInitialCamera: _initialCameraPosition,
                        mapCircles: _safeZoneCircles,
                        mapMarkers: _patientMarkers,
                        onMapCreated: _onMapCreated,
                        onRecenter: _animateMapToPatient,
                      )
                : _selectedTab == 1
                    // Editor directly (like Doctor screen)
                    ? _loadingZones
                        ? const Center(child: CircularProgressIndicator())
                        : _SafeZonesEditorView(
                            patientName: _patientName ?? 'Patient',
                            zones: _safeZones,
                            isInside: _isInsideZone,
                            onToggle: (i, val) async {
                              try {
                                final zone = _safeZones[i];
                                if (zone.id != null) {
                                  await _safeZoneService.toggleSafeZone(
                                    zone.id!,
                                    val,
                                  );
                                  await _loadSafeZones();
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to update: $e')),
                                  );
                                }
                              }
                            },
                            onDelete: (i) async {
                              final z = _safeZones[i];
                              final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text(tr('Delete Safe Zone', 'حذف المنطقة الآمنة')),
                                      content: Text(
                                          tr('Are you sure you want to delete "${z.name}"?', 'هل أنت متأكد أنك تريد حذف "${z.name}"؟')),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text(tr('Cancel', 'إلغاء')),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text(tr('Delete', 'حذف'),
                                              style: const TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                              if (confirmed && z.id != null) {
                                try {
                                  await _safeZoneService.deleteSafeZone(z.id!);
                                  await _loadSafeZones();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to delete: $e')),
                                    );
                                  }
                                }
                              }
                            },
                            onAddPressed: () => _openAddSafeZoneSheet(
                              onAdd: (newZone) async {
                                if (_selectedPatientUserId == null) return;
                                try {
                                  await _safeZoneService.createSafeZone(
                                    patientUserId: _selectedPatientUserId!,
                                    name: newZone.name,
                                    address: newZone.address,
                                    latitude: newZone.lat,
                                    longitude: newZone.lng,
                                    radiusMeters: newZone.radiusMeters.toInt(),
                                    isActive: newZone.isActive,
                                  );
                                  await _loadSafeZones();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(tr('Failed to add', 'فشل الإضافة') + ': $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          )
                    : _loadingHistory
                        ? const Center(child: CircularProgressIndicator())
                        : _history.isEmpty
                            ? Center(
                                child: Text(tr('No location history available', 'لا يوجد سجل مواقع متاح')),
                              )
                            : _HistoryView(
                                entries: _history.map((h) {
                                  final lat = h['latitude'] as double?;
                                  final lng = h['longitude'] as double?;
                                  final address = h['address'] as String?;
                                  final createdAt = h['created_at'] != null
                                      ? DateTime.parse(h['created_at'] as String)
                                      : DateTime.now();
                                  
                                  // Determine place name from address or coordinates
                                  String place = tr('Unknown', 'غير معروف');
                                  IconData icon = Icons.place;
                                  Color color = AppTheme.teal500;
                                  
                                  if (address != null && address.isNotEmpty) {
                                    place = address.split(',').first;
                                    if (address.toLowerCase().contains('home')) {
                                      icon = Icons.home;
                                      color = Colors.green;
                                    } else if (address.toLowerCase().contains('hospital')) {
                                      icon = Icons.local_hospital;
                                      color = Colors.red;
                                    } else if (address.toLowerCase().contains('park')) {
                                      icon = Icons.park;
                                      color = AppTheme.teal500;
                                    }
                                  }

                                  return _HistoryEntry(
                                    place: place,
                                    address: address ?? 'No address',
                                    timeLabel: _timeAgo(createdAt),
                                    durationLabel: '—',
                                    icon: icon,
                                    color: color,
                                    lat: lat ?? 0.0,
                                    lng: lng ?? 0.0,
                                  );
                                }).toList(),
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
  final CameraPosition mapInitialCamera;
  final Set<Circle> mapCircles;
  final Set<Marker> mapMarkers;
  final void Function(GoogleMapController) onMapCreated;
  final VoidCallback onRecenter;

  const _LiveTrackingView({
    required this.isInsideAny,
    required this.statusText,
    required this.statusColor,
    required this.address,
    required this.lastUpdatedLabel,
    required this.onRefresh,
    required this.onDirections,
    required this.mapInitialCamera,
    required this.mapCircles,
    required this.mapMarkers,
    required this.onMapCreated,
    required this.onRecenter,
  });

  String _tr(BuildContext context, String en, String ar) {
    final isAr = (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ar';
    return isAr ? ar : en;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map Area
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: mapInitialCamera,
                markers: mapMarkers,
                circles: mapCircles,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                compassEnabled: false,
                onMapCreated: onMapCreated,
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    const SizedBox(height: 12),
                    FloatingActionButton.small(
                      heroTag: 'family_map_recenter',
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.teal600,
                      onPressed: onRecenter,
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
            ],
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
                        Text(
                          _tr(context, 'Current Location', 'الموقع الحالي'),
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
                            fontSize: 14,
                            color: AppTheme.gray600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tr(context, 'Last updated', 'آخر تحديث') + ': $lastUpdatedLabel',
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
                  label: Text(_tr(context, 'Get Directions to Patient', 'الحصول على اتجاهات للمريض')),
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
  final List<SafeZone> zones;
  final bool Function(SafeZone) isInside;
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

  String _tr(BuildContext context, String en, String ar) {
    final isAr = (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ar';
    return isAr ? ar : en;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.lightGradient),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${_tr(context, 'Safe Zones', 'المناطق الآمنة')} • $patientName',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.teal900,
            ),
          ),
          const SizedBox(height: 12),
          if (zones.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  _tr(context, 'No safe zones yet. Add one to get started.', 'لا توجد مناطق آمنة بعد. أضف واحدة للبدء.'),
                  style: const TextStyle(color: AppTheme.gray500),
                ),
              ),
            )
          else
            ...List.generate(zones.length, (i) {
              final z = zones[i];
              final inside = isInside(z);
              return Padding(
                padding: EdgeInsets.only(bottom: i == zones.length - 1 ? 0 : 12),
                child: _SafeZoneCardRow(
                  name: z.name,
                  address: z.address ?? '—',
                  radius: '${z.radiusMeters}m',
                  isActive: z.isActive,
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
              label: Text(_tr(context, 'Add New Safe Zone', 'إضافة منطقة آمنة جديدة')),
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
  final List<_HistoryEntry> entries;
  final void Function(double lat, double lng, String label) onOpenMap;

  const _HistoryView({
    required this.entries,
    required this.onOpenMap,
  });

  String _tr(BuildContext context, String en, String ar) {
    final isAr = (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ar';
    return isAr ? ar : en;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.lightGradient),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _tr(context, 'Location History', 'سجل المواقع'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.teal900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _tr(context, 'Places visited recently', 'الأماكن التي تم زيارتها مؤخراً'),
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.gray600,
            ),
          ),
          const SizedBox(height: 16),
          ...entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryItem(
                  place: e.place,
                  address: e.address,
                  time: e.timeLabel,
                  duration: e.durationLabel,
                  icon: e.icon,
                  color: e.color,
                  onDirections: () => onOpenMap(e.lat, e.lng, e.place),
                ),
              )),
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

  String _tr(BuildContext context, String en, String ar) {
    final isAr = (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ar';
    return isAr ? ar : en;
  }

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
                label: Text(_tr(context, 'Directions', 'الاتجاهات')),
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