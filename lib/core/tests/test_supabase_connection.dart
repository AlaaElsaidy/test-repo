// lib/core/tests/test_supabase_connection.dart
// اختبار الاتصال بـ Supabase والتحقق من الجداول

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> testSupabaseConnection() async {
  try {
    print('🔍 اختبار الاتصال بـ Supabase...');
    
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    
    print('✓ الاتصال بـ Supabase: نجح');
    print('👤 المستخدم الحالي: ${session?.user.email}');
    print('📍 User ID: ${session?.user.id}');
    
    // اختبار جدول safe_zones
    print('\n🔍 فحص جدول safe_zones...');
    try {
      final response = await client
          .from('safe_zones')
          .select()
          .limit(1);
      print('✓ جدول safe_zones موجود - عدد الصفوف: ${(response as List).length}');
    } catch (e) {
      print('✗ خطأ في جدول safe_zones: $e');
    }
    
    // اختبار جدول location_updates
    print('\n🔍 فحص جدول location_updates...');
    try {
      final response = await client
          .from('location_updates')
          .select()
          .limit(1);
      print('✓ جدول location_updates موجود - عدد الصفوف: ${(response as List).length}');
    } catch (e) {
      print('✗ خطأ في جدول location_updates: $e');
    }
    
    // اختبار جدول location_history
    print('\n🔍 فحص جدول location_history...');
    try {
      final response = await client
          .from('location_history')
          .select()
          .limit(1);
      print('✓ جدول location_history موجود - عدد الصفوف: ${(response as List).length}');
    } catch (e) {
      print('✗ خطأ في جدول location_history: $e');
    }
    
    // اختبار جدول emergency_contacts
    print('\n🔍 فحص جدول emergency_contacts...');
    try {
      final response = await client
          .from('emergency_contacts')
          .select()
          .limit(1);
      print('✓ جدول emergency_contacts موجود - عدد الصفوف: ${(response as List).length}');
    } catch (e) {
      print('✗ خطأ في جدول emergency_contacts: $e');
    }
    
    // محاولة إدراج سجل تجريبي في location_updates
    print('\n🔍 اختبار الإدراج في location_updates...');
    try {
      final patientId = session?.user.id ?? 'test-patient-id';
      
      final response = await client
          .from('location_updates')
          .insert({
            'patient_id': patientId,
            'latitude': 30.0131,
            'longitude': 31.2089,
            'address': 'Test Location',
            'accuracy': 10.0,
            'timestamp': DateTime.now().toIso8601String(),
          })
          .select();
      
      print('✓ تم الإدراج بنجاح في location_updates');
      print('📊 البيانات المدرجة: $response');
    } catch (e) {
      print('✗ خطأ في الإدراج: $e');
    }
    
  } catch (e) {
    print('❌ خطأ عام في الاتصال: $e');
  }
}
