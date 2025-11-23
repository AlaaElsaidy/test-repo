// lib/screens/family/tracking/widgets/add_safe_zone_dialog.dart
// dialog لإضافة منطقة آمنة جديدة

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../core/models/tracking_models.dart';
import '../../../../core/repositories/tracking_repository.dart';

class AddSafeZoneDialog extends StatefulWidget {
  final String patientId;
  final TrackingRepository trackingRepository;

  const AddSafeZoneDialog({
    Key? key,
    required this.patientId,
    required this.trackingRepository,
  }) : super(key: key);

  @override
  State<AddSafeZoneDialog> createState() => _AddSafeZoneDialogState();
}

class _AddSafeZoneDialogState extends State<AddSafeZoneDialog> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  double _radius = 150;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  /// جلب آخر موقع للمريض من Supabase
  Future<void> _usePatientLocation() async {
    try {
      setState(() => _isLoading = true);
      
      final location = 
          await widget.trackingRepository.getLastLocation(widget.patientId);
      
      if (location == null) {
        _showSnackBar('لم يتم العثور على موقع للمريض');
        return;
      }

      setState(() {
        _latController.text = location.latitude.toStringAsFixed(6);
        _lngController.text = location.longitude.toStringAsFixed(6);
        if (location.address != null && location.address!.isNotEmpty) {
          _addressController.text = location.address!;
        }
      });

      _showSnackBar('تم جلب موقع المريض بنجاح');
    } catch (e) {
      _showSnackBar('خطأ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// جلب موقع الفرد الحالي
  Future<void> _useMyLocation() async {
    try {
      setState(() => _isLoading = true);

      // التحقق من الصلاحيات
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied ||
            newPermission == LocationPermission.deniedForever) {
          _showSnackBar('لم يتم منح صلاحية الموقع');
          return;
        }
      }

      // جلب الموقع
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // الحصول على العنوان
      String address = '';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[];
          if (p.street != null && p.street!.isNotEmpty) {
            parts.add(p.street!);
          }
          if (p.locality != null && p.locality!.isNotEmpty) {
            parts.add(p.locality!);
          }
          address = parts.join(', ');
        }
      } catch (_) {
        // تجاهل الأخطاء
      }

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
        if (address.isNotEmpty) {
          _addressController.text = address;
        }
      });

      _showSnackBar('تم جلب موقعك الحالي');
    } catch (e) {
      _showSnackBar('خطأ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// استخدام موقع مقترح
  void _useSuggestedLocation(String name, double lat, double lng) {
    setState(() {
      _nameController.text = name;
      _latController.text = lat.toStringAsFixed(6);
      _lngController.text = lng.toStringAsFixed(6);
    });
  }

  /// حفظ المنطقة الآمنة
  Future<void> _saveZone() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar('الرجاء إدخال اسم المنطقة');
      return;
    }

    if (_latController.text.isEmpty || _lngController.text.isEmpty) {
      _showSnackBar('الرجاء إدخال الإحداثيات');
      return;
    }

    try {
      setState(() => _isLoading = true);

      final zone = SafeZone(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: widget.patientId,
        name: _nameController.text,
        address: _addressController.text.isNotEmpty 
            ? _addressController.text 
            : null,
        latitude: double.parse(_latController.text),
        longitude: double.parse(_lngController.text),
        radiusMeters: _radius,
        isActive: _isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await widget.trackingRepository.createSafeZone(
        name: zone.name,
        address: zone.address,
        patientId: zone.patientId,
        latitude: zone.latitude,
        longitude: zone.longitude,
        radiusMeters: _radius,
        isActive: zone.isActive,
      );
      
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('تم حفظ المنطقة الآمنة بنجاح');
      }
    } catch (e) {
      _showSnackBar('خطأ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// عرض رسالة
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الرأس
              const Text(
                'Add Safe Zone',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // أزرار الموقع
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _usePatientLocation,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Use patient location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _useMyLocation,
                    icon: const Icon(Icons.gps_fixed),
                    label: const Text('Use my location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // المواقع المقترحة
              Wrap(
                spacing: 8,
                children: [
                  _buildSuggestedButton('Home', 30.0444, 31.2357),
                  _buildSuggestedButton('Park', 30.0500, 31.2400),
                  _buildSuggestedButton('Hospital', 30.0388, 31.2300),
                ],
              ),
              const SizedBox(height: 24),

              // الاسم
              const Text(
                'Name',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'New Zone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // العنوان
              const Text(
                'Address',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Optional address/description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // الإحداثيات
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Latitude',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _latController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          readOnly: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Longitude',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _lngController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          readOnly: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Radius Slider
              Text(
                'Radius: ${_radius.toStringAsFixed(0)} m',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _radius,
                min: 50,
                max: 1000,
                divisions: 19,
                onChanged: (value) {
                  setState(() => _radius = value);
                },
                activeColor: Colors.teal,
              ),
              const SizedBox(height: 16),

              // Active Toggle
              Row(
                children: [
                  const Text(
                    'Active',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isActive,
                    onChanged: (value) {
                      setState(() => _isActive = value);
                    },
                    activeColor: Colors.teal,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // أزرار الإجراء
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading 
                          ? null 
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveZone,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Save Safe Zone'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// زر الموقع المقترح
  Widget _buildSuggestedButton(String label, double lat, double lng) {
    return OutlinedButton.icon(
      onPressed: () => _useSuggestedLocation(label, lat, lng),
      icon: const Icon(Icons.location_on, size: 16),
      label: Text(label),
    );
  }
}
