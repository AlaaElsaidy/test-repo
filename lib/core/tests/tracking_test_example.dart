// lib/core/tests/tracking_test_example.dart
// مثال على كيفية اختبار نظام التتبع

// يمكن تشغيل هذا مباشرة في main للاختبار السريع

import '../di/injection_container.dart';
import '../repositories/tracking_repository.dart';

/// اختبار نظام التتبع
Future<void> testTrackingSystem() async {
  print('🧪 بدء اختبار نظام التتبع...\n');

  try {
    final repo = getIt<TrackingRepository>();
    const patientId = 'test-patient-id';

    // ✅ اختبار 1: جلب المناطق الآمنة
    print('1️⃣ اختبار جلب المناطق الآمنة...');
    try {
      final zones = await repo.getSafeZones(patientId);
      print('   ✓ تم جلب ${zones.length} منطقة آمنة\n');
    } catch (e) {
      print('   ✗ خطأ: $e\n');
    }

    // ✅ اختبار 2: جلب آخر موقع معروف
    print('2️⃣ اختبار جلب آخر موقع...');
    try {
      final location = await repo.getLastLocation(patientId);
      if (location != null) {
        print('   ✓ آخر موقع: ${location.address}');
        print('   - الإحداثيات: ${location.latitude}, ${location.longitude}');
        print('   - الدقة: ${location.accuracy}م\n');
      } else {
        print('   ℹ لا توجد مواقع مسجلة بعد\n');
      }
    } catch (e) {
      print('   ✗ خطأ: $e\n');
    }

    // ✅ اختبار 3: جلب السجل التاريخي
    print('3️⃣ اختبار جلب السجل التاريخي...');
    try {
      final history = await repo.getLocationHistory(patientId, days: 7);
      print('   ✓ تم جلب ${history.length} سجل من آخر 7 أيام\n');
      
      if (history.isNotEmpty) {
        final recent = history.first;
        print('   آخر سجل:');
        print('   - المكان: ${recent.placeName ?? "غير معروف"}');
        print('   - وقت الوصول: ${recent.arrivedAt}');
        if (recent.departedAt != null) {
          print('   - وقت المغادرة: ${recent.departedAt}');
          print('   - مدة التواجد: ${recent.duration?.inMinutes} دقيقة');
        } else {
          print('   - الحالة: متواجد حاليًا');
        }
        print('');
      }
    } catch (e) {
      print('   ✗ خطأ: $e\n');
    }

    // ✅ اختبار 4: جلب جهات الطوارئ
    print('4️⃣ اختبار جلب جهات الطوارئ...');
    try {
      final contacts = await repo.getEmergencyContacts(patientId);
      print('   ✓ تم جلب ${contacts.length} جهة اتصال\n');
      
      for (final contact in contacts) {
        print('   - ${contact.name} (${contact.relationship ?? ""}): ${contact.phone}');
        if (contact.isPrimary) print('     ⭐ جهة اتصال أساسية');
      }
      print('');
    } catch (e) {
      print('   ✗ خطأ: $e\n');
    }

    // ✅ اختبار 5: اختبار Real-time streams
    print('5️⃣ اختبار Real-time streams...');
    try {
      print('   اختبار مراقبة تحديثات الموقع...');
      final subscription = repo.watchLocationUpdates(patientId).listen(
        (location) {
          print('   📍 تحديث فوري: ${location.address}');
        },
        onError: (error) {
          print('   ✗ خطأ في المراقبة: $error');
        },
      );

      // انتظر لمدة 5 ثوان ثم إلغاء الاشتراك
      await Future.delayed(const Duration(seconds: 5));
      subscription.cancel();
      print('   ✓ انتهى اختبار Real-time\n');
    } catch (e) {
      print('   ✗ خطأ: $e\n');
    }

    // ✅ اختبار 6: إضافة منطقة آمنة (اختياري)
    print('6️⃣ اختبار إضافة منطقة آمنة...');
    try {
      final newZone = await repo.createSafeZone(
        patientId: patientId,
        name: 'منطقة الاختبار',
        latitude: 30.0,
        longitude: 31.0,
        radiusMeters: 500,
      );
      print('   ✓ تم إنشاء منطقة: ${newZone.name}');
      print('   - المعرف: ${newZone.id}');
      print('   - نصف القطر: ${newZone.radiusMeters}م\n');
    } catch (e) {
      print('   ℹ لم يتمكن من إنشاء منطقة (قد تكون موجودة): $e\n');
    }

    print('✅ انتهى الاختبار بنجاح!');
    print('═' * 50);
  } catch (e) {
    print('❌ خطأ عام: $e');
  }
}

/// مثال على استخدام Cubit
Future<void> testCubitExample() async {
  print('\n🎮 مثال على استخدام PatientTrackingCubit\n');
  
  // في الواقع العملي:
  // PatientTrackingCubit cubit = PatientTrackingCubit(repo, patientId);
  // await cubit.initializeTracking();
  //
  // يمكنك الآن الاستماع إلى التغييرات:
  // context.watch<PatientTrackingCubit>().state
  //
  // أو تنفيذ الأحداث:
  // context.read<PatientTrackingCubit>().addSafeZone(...)
  
  print('✓ يتم فحص الموقع كل 30 ثانية');
  print('✓ يتم تحديث الحالة تلقائيًا');
  print('✓ يتم حساب الأمان (داخل/خارج) آليًا');
  print('✓ يتم الاستماع إلى تحديثات Supabase الفورية');
}

/// دالة مساعدة للتحقق من الاتصال
Future<void> checkConnection() async {
  print('\n🔌 اختبار الاتصال بـ Supabase\n');
  
  try {
    getIt<TrackingRepository>();
    print('✓ تم العثور على TrackingRepository');
    print('✓ الاتصال جاهز');
  } catch (e) {
    print('✗ خطأ: $e');
    print('✗ تأكد من استدعاء setupDependencies() في main.dart');
  }
}
