// lib/core/tests/quick_test.dart
// اختبار سريع لنظام التتبع بدون الحاجة لـ UI كاملة

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'seed_tracking_data.dart';
import 'test_supabase_connection.dart';

class QuickTestScreen extends StatefulWidget {
  const QuickTestScreen({Key? key}) : super(key: key);

  @override
  State<QuickTestScreen> createState() => _QuickTestScreenState();
}

class _QuickTestScreenState extends State<QuickTestScreen> {
  String output = '🔍 اختبارات النظام\n';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _addLog('بدء البرنامج...');
  }

  void _addLog(String message) {
    setState(() {
      output += '\n$message';
    });
  }

  Future<void> _testConnection() async {
    _addLog('\n⏳ جاري اختبار الاتصال بـ Supabase...');
    setState(() => isLoading = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user != null) {
        _addLog('✅ المستخدم: ${user.email}');
        _addLog('✅ User ID: ${user.id}');
      } else {
        _addLog('⚠️  لا يوجد مستخدم مسجل دخول');
      }

      // اختبار الجداول
      final tables = ['safe_zones', 'location_updates', 'location_history', 'emergency_contacts'];
      
      for (var table in tables) {
        try {
          final response = await client
              .from(table)
              .select('id')
              .limit(1);
          final count = (response as List).length;
          _addLog('✅ جدول $table: موجود ($count سجل)');
        } catch (e) {
          _addLog('❌ خطأ في جدول $table: $e');
        }
      }
    } catch (e) {
      _addLog('❌ خطأ في الاتصال: $e');
    }

    setState(() => isLoading = false);
  }

  Future<void> _seedData() async {
    _addLog('\n⏳ جاري ملء البيانات التجريبية...');
    setState(() => isLoading = true);

    try {
      await seedTrackingData();
      _addLog('✅ تمت عملية ملء البيانات بنجاح!');
    } catch (e) {
      _addLog('❌ خطأ: $e');
    }

    setState(() => isLoading = false);
  }

  Future<void> _checkTables() async {
    _addLog('\n⏳ جاري فحص محتوى الجداول...');
    setState(() => isLoading = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        _addLog('❌ لا يوجد مستخدم مسجل دخول');
        return;
      }

      // فحص Safe Zones
      final zones = await client
          .from('safe_zones')
          .select()
          .eq('patient_id', user.id);
      _addLog('📍 Safe Zones: ${(zones as List).length} منطقة');
      
      // فحص Location Updates
      final locations = await client
          .from('location_updates')
          .select()
          .eq('patient_id', user.id);
      _addLog('📍 Location Updates: ${(locations as List).length} تحديث');

      // فحص Location History
      final history = await client
          .from('location_history')
          .select()
          .eq('patient_id', user.id);
      _addLog('📍 Location History: ${(history as List).length} سجل');

      // فحص Emergency Contacts
      final contacts = await client
          .from('emergency_contacts')
          .select()
          .eq('patient_id', user.id);
      _addLog('📞 Emergency Contacts: ${(contacts as List).length} جهة اتصال');

      _addLog('\n✅ فحص اكتمل بنجاح!');
    } catch (e) {
      _addLog('❌ خطأ: $e');
    }

    setState(() => isLoading = false);
  }

  Future<void> _clearData() async {
    _addLog('\n⏳ جاري حذف البيانات...');
    setState(() => isLoading = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        _addLog('❌ لا يوجد مستخدم');
        return;
      }

      final tables = ['location_history', 'location_updates', 'safe_zones', 'emergency_contacts'];
      
      for (var table in tables) {
        try {
          await client
              .from(table)
              .delete()
              .eq('patient_id', user.id);
          _addLog('✓ تم حذف بيانات من $table');
        } catch (e) {
          _addLog('⚠️  خطأ في حذف $table: $e');
        }
      }

      _addLog('✅ تم حذف جميع البيانات');
    } catch (e) {
      _addLog('❌ خطأ: $e');
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار نظام التتبع'),
        backgroundColor: Colors.blue[700],
      ),
      body: Column(
        children: [
          // الأزرار
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _testConnection,
                  icon: const Icon(Icons.cloud),
                  label: const Text('اختبار الاتصال'),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _checkTables,
                  icon: const Icon(Icons.table_chart),
                  label: const Text('فحص الجداول'),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _seedData,
                  icon: const Icon(Icons.add_circle),
                  label: const Text('ملء البيانات'),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _clearData,
                  icon: const Icon(Icons.delete),
                  label: const Text('حذف البيانات'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          
          // Output
          Expanded(
            child: Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Text(
                  output,
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),

          // Loading Indicator
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
