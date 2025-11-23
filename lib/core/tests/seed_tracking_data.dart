// lib/core/tests/seed_tracking_data.dart
// ملء البيانات التجريبية لاختبار نظام التتبع

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tracking_models.dart';

Future<void> seedTrackingData() async {
  try {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId == null) {
      print('❌ المستخدم غير مسجل دخول');
      return;
    }

    print('🌱 بدء ملء البيانات التجريبية...');
    print('👤 User ID: $userId');

    // 1️⃣ إضافة منطقة آمنة (Safe Zone)
    print('\n📍 إضافة مناطق آمنة...');
    try {
      final safeZones = [
        {
          'patient_id': userId,
          'name': 'المنزل',
          'address': 'شارع النيل، القاهرة',
          'latitude': 30.0131,
          'longitude': 31.2089,
          'radius_meters': 500,
          'is_active': true,
        },
        {
          'patient_id': userId,
          'name': 'المستشفى',
          'address': 'المعادي، القاهرة',
          'latitude': 30.0096,
          'longitude': 31.2233,
          'radius_meters': 300,
          'is_active': true,
        },
        {
          'patient_id': userId,
          'name': 'المدرسة',
          'address': 'الدقي، الجيزة',
          'latitude': 30.0444,
          'longitude': 31.2357,
          'radius_meters': 200,
          'is_active': true,
        },
      ];

      for (var zone in safeZones) {
        try {
          await client.from('safe_zones').insert(zone);
          print('✓ تمت إضافة منطقة: ${zone['name']}');
        } catch (e) {
          print('⚠️  الحد الأدنى للمناطق موجود بالفعل: ${zone['name']}');
        }
      }
    } catch (e) {
      print('❌ خطأ في إضافة المناطق الآمنة: $e');
    }

    // 2️⃣ إضافة تحديثات الموقع (Location Updates)
    print('\n📍 إضافة تحديثات الموقع...');
    try {
      final locations = [
        {
          'patient_id': userId,
          'latitude': 30.0131,
          'longitude': 31.2089,
          'address': 'شارع النيل، القاهرة',
          'accuracy': 15.0,
          'timestamp': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        },
        {
          'patient_id': userId,
          'latitude': 30.0145,
          'longitude': 31.2105,
          'address': 'بالقرب من شارع النيل',
          'accuracy': 20.0,
          'timestamp': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        },
        {
          'patient_id': userId,
          'latitude': 30.0158,
          'longitude': 31.2120,
          'address': 'قريب من المنزل',
          'accuracy': 10.0,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ];

      for (var location in locations) {
        try {
          await client.from('location_updates').insert(location);
          print('✓ تمت إضافة تحديث موقع: ${location['address']}');
        } catch (e) {
          print('⚠️  خطأ في إضافة الموقع: $e');
        }
      }
    } catch (e) {
      print('❌ خطأ في إضافة تحديثات الموقع: $e');
    }

    // 3️⃣ إضافة سجل الموقع (Location History)
    print('\n📍 إضافة سجل المواقع...');
    try {
      final history = [
        {
          'patient_id': userId,
          'place_name': 'المنزل',
          'address': 'شارع النيل، القاهرة',
          'latitude': 30.0131,
          'longitude': 31.2089,
          'arrived_at': DateTime.now().subtract(Duration(hours: 3)).toIso8601String(),
          'departed_at': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
          'duration_minutes': 60,
        },
        {
          'patient_id': userId,
          'place_name': 'المستشفى',
          'address': 'المعادي، القاهرة',
          'latitude': 30.0096,
          'longitude': 31.2233,
          'arrived_at': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
          'departed_at': DateTime.now().subtract(Duration(minutes: 30)).toIso8601String(),
          'duration_minutes': 90,
        },
        {
          'patient_id': userId,
          'place_name': 'المدرسة',
          'address': 'الدقي، الجيزة',
          'latitude': 30.0444,
          'longitude': 31.2357,
          'arrived_at': DateTime.now().subtract(Duration(minutes: 30)).toIso8601String(),
          'departed_at': null,
          'duration_minutes': null,
        },
      ];

      for (var record in history) {
        try {
          await client.from('location_history').insert(record);
          print('✓ تمت إضافة سجل: ${record['place_name']}');
        } catch (e) {
          print('⚠️  خطأ في إضافة السجل: $e');
        }
      }
    } catch (e) {
      print('❌ خطأ في إضافة سجل المواقع: $e');
    }

    // 4️⃣ إضافة جهات الاتصال الطارئة (Emergency Contacts)
    print('\n📞 إضافة جهات الاتصال الطارئة...');
    try {
      final contacts = [
        {
          'patient_id': userId,
          'name': 'أم أحمد',
          'phone': '+201001234567',
          'relationship': 'أم',
        },
        {
          'patient_id': userId,
          'name': 'أبو أحمد',
          'phone': '+201001234568',
          'relationship': 'أب',
        },
        {
          'patient_id': userId,
          'name': 'عم أحمد',
          'phone': '+201001234569',
          'relationship': 'عم',
        },
      ];

      for (var contact in contacts) {
        try {
          await client.from('emergency_contacts').insert(contact);
          print('✓ تمت إضافة جهة اتصال: ${contact['name']}');
        } catch (e) {
          print('⚠️  خطأ في إضافة جهة الاتصال: $e');
        }
      }
    } catch (e) {
      print('❌ خطأ في إضافة جهات الاتصال: $e');
    }

    print('\n✅ تمت عملية ملء البيانات بنجاح!');
    print('📊 يمكنك الآن رؤية البيانات في الشاشات');

  } catch (e) {
    print('❌ خطأ عام في ملء البيانات: $e');
  }
}
