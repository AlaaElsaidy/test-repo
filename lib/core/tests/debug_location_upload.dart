// lib/core/tests/debug_location_upload.dart
// أداة تصحيح مشاكل رفع الموقع

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/tracking_repository.dart';

class DebugLocationUploadScreen extends StatefulWidget {
  final TrackingRepository trackingRepository;

  const DebugLocationUploadScreen({
    Key? key,
    required this.trackingRepository,
  }) : super(key: key);

  @override
  State<DebugLocationUploadScreen> createState() =>
      _DebugLocationUploadScreenState();
}

class _DebugLocationUploadScreenState extends State<DebugLocationUploadScreen> {
  String logs = '📋 Debug Logs\n';
  bool isLoading = false;

  void addLog(String message) {
    print(message); // طباعة في console أيضاً
    setState(() {
      logs += '\n$message';
    });
  }

  Future<void> checkPermissions() async {
    addLog('\n🔐 جاري فحص الـ Permissions...');
    setState(() => isLoading = true);

    try {
      final permission = await Geolocator.checkPermission();
      addLog('✅ الـ Permission الحالي: $permission');

      if (permission == LocationPermission.denied) {
        addLog('⚠️ الـ Permission مرفوض، جاري الطلب...');
        final newPermission = await Geolocator.requestPermission();
        addLog('✅ النتيجة: $newPermission');
      } else if (permission == LocationPermission.deniedForever) {
        addLog('❌ الـ Permission مرفوض دائماً');
      } else {
        addLog('✅ الـ Permission موافق عليه');
      }
    } catch (e) {
      addLog('❌ خطأ: $e');
    }

    setState(() => isLoading = false);
  }

  Future<void> getLocation() async {
    addLog('\n📍 جاري جلب الموقع...');
    setState(() => isLoading = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      addLog('✅ تم جلب الموقع:');
      addLog('   - Latitude: ${position.latitude}');
      addLog('   - Longitude: ${position.longitude}');
      addLog('   - Accuracy: ${position.accuracy}');
      addLog('   - Speed: ${position.speed}');
    } catch (e) {
      addLog('❌ خطأ: $e');
    }

    setState(() => isLoading = false);
  }

  Future<void> testSupabaseConnection() async {
    addLog('\n🌐 جاري اختبار الاتصال بـ Supabase...');
    setState(() => isLoading = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        addLog('❌ لا يوجد مستخدم مسجل دخول!');
        return;
      }

      addLog('✅ المستخدم: ${user.email}');
      addLog('   - ID: ${user.id}');

      // اختبر الجدول
      final response = await client
          .from('location_updates')
          .select('id')
          .limit(1);

      addLog('✅ الاتصال بـ location_updates ناجح');
      addLog('   - عدد الصفوف: ${(response as List).length}');
    } catch (e) {
      addLog('❌ خطأ في الاتصال: $e');
    }

    setState(() => isLoading = false);
  }

  Future<void> uploadLocationTest() async {
    addLog('\n📤 جاري اختبار رفع الموقع...');
    setState(() => isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        addLog('❌ لا يوجد مستخدم مسجل دخول!');
        return;
      }

      addLog('1️⃣ جاري جلب الموقع من GPS...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      addLog('✅ تم جلب الموقع');

      addLog('2️⃣ جاري إرسال الموقع لـ Supabase...');
      final result = await widget.trackingRepository.updateLocation(
        patientId: user.id,
        latitude: position.latitude,
        longitude: position.longitude,
        address: 'Test Location',
        accuracy: position.accuracy,
      );

      addLog('✅ تم الإرسال بنجاح!');
      addLog('   - ID: ${result.id}');
      addLog('   - Location: ${result.latitude}, ${result.longitude}');

      // التحقق من البيانات
      addLog('3️⃣ جاري التحقق من البيانات...');
      final lastLocation = await widget.trackingRepository.getLastLocation(user.id);
      if (lastLocation != null) {
        addLog('✅ تم التحقق:');
        addLog('   - Latest: ${lastLocation.latitude}, ${lastLocation.longitude}');
      }
    } catch (e) {
      addLog('❌ خطأ: $e');
    }

    setState(() => isLoading = false);
  }

  Future<void> checkDatabaseData() async {
    addLog('\n🗄️ جاري فحص البيانات في Database...');
    setState(() => isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        addLog('❌ لا يوجد مستخدم');
        return;
      }

      final response = await Supabase.instance.client
          .from('location_updates')
          .select()
          .eq('patient_id', user.id)
          .order('timestamp', ascending: false)
          .limit(5);

      final locations = response as List;
      addLog('✅ عدد السجلات: ${locations.length}');

      for (int i = 0; i < locations.length; i++) {
        final loc = locations[i];
        addLog('   [$i] ${loc['latitude']}, ${loc['longitude']} @ ${loc['timestamp']}');
      }
    } catch (e) {
      addLog('❌ خطأ: $e');
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Debug Location Upload'),
        backgroundColor: Colors.red[700],
      ),
      body: Column(
        children: [
          // Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: isLoading ? null : checkPermissions,
                  icon: const Icon(Icons.security),
                  label: const Text('فحص Permission'),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : getLocation,
                  icon: const Icon(Icons.location_on),
                  label: const Text('جلب الموقع'),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : testSupabaseConnection,
                  icon: const Icon(Icons.cloud),
                  label: const Text('اختبار الاتصال'),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : uploadLocationTest,
                  icon: const Icon(Icons.upload),
                  label: const Text('اختبار الرفع'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : checkDatabaseData,
                  icon: const Icon(Icons.storage),
                  label: const Text('فحص Database'),
                ),
              ],
            ),
          ),
          // Logs
          Expanded(
            child: Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Text(
                  logs,
                  style: TextStyle(
                    color: Colors.green[400],
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
          // Loading
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('جاري المعالجة...'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
