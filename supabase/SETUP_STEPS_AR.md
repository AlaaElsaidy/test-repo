🔧 خطوات تطبيق السوبابيز - Step by Step
==========================================

👇 اتبع هذه الخطوات بالترتيب بالضبط:

---

**الخطوة 1️⃣: تطبيق جداول قاعدة البيانات (5 دقائق)**

✅ الملف: supabase/migrations/20251122_create_tracking_tables.sql

الخطوات:
1. اذهب إلى: https://app.supabase.com
2. اختر مشروعك
3. اضغط على: SQL Editor (في القائمة اليسرى)
4. اضغط: "New Query" (الزر الأزرق)
5. انسخ **كل محتوى** ملف 20251122_create_tracking_tables.sql
6. الصقه في الـ SQL Editor
7. اضغط: Execute (أو الزر الأسود Run)

✓ يجب تشوف: "Successfully executed"

---

**الخطوة 2️⃣: تفعيل Real-time (2 دقيقة)**

✅ الملف: supabase/SETUP_QUERIES.sql (الجزء 1️⃣)

الخطوات:
1. انسخ الـ Queries التالية من SETUP_QUERIES.sql:

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE safe_zones;
ALTER PUBLICATION supabase_realtime ADD TABLE location_updates;
ALTER PUBLICATION supabase_realtime ADD TABLE location_history;
ALTER PUBLICATION supabase_realtime ADD TABLE emergency_contacts;
```

2. اضغط: "New Query" مرة أخرى
3. الصق الكود
4. اضغط: Execute

✓ يجب تشوف: "Successfully executed"

---

**الخطوة 3️⃣: التحقق من البيانات (2 دقيقة)**

✅ الملف: supabase/SETUP_QUERIES.sql (الجزء 5️⃣)

الخطوات:
1. نسخ هذا الكويري:

```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('safe_zones', 'location_updates', 'location_history', 'emergency_contacts');
```

2. اضغط: "New Query"
3. الصق الكود
4. اضغط: Execute

✓ النتيجة المتوقعة:
```
table_name
─────────────────────
safe_zones
location_updates
location_history
emergency_contacts
```

---

**الخطوة 4️⃣: التحقق من الأمان (RLS Policies) (1 دقيقة)**

✅ الملف: supabase/SETUP_QUERIES.sql (الجزء 2️⃣)

الخطوات:
1. نسخ هذا الكويري:

```sql
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename IN ('safe_zones', 'location_updates', 'location_history', 'emergency_contacts')
ORDER BY tablename, policyname;
```

2. اضغط: "New Query"
3. الصق الكود
4. اضغط: Execute

✓ يجب تشوف: 13 سياسة أمان (3-4 لكل جدول)

---

**الخطوة 5️⃣: إضافة بيانات اختبار (اختياري - 3 دقائق)**

✅ الملف: supabase/SETUP_QUERIES.sql (الجزء 4️⃣)

الخطوات:
1. اذهب إلى Supabase Dashboard
2. اضغط: "Table Editor" (في القائمة اليسرى)
3. اختر جدول: safe_zones
4. اضغط: "Insert Row" (الزر الأسود)
5. أضف البيانات:

```
id: (سيُملأ تلقائيًا)
patient_id: ce4aee1d-0084-4953-997d-ddea1fdb4a50
name: البيت
address: القاهرة
latitude: 30.0444
longitude: 31.2357
radius_meters: 500
is_active: true
created_at: (سيُملأ تلقائيًا)
updated_at: (سيُملأ تلقائيًا)
```

✓ يجب تشوف: الصف الجديد ظهر في الجدول

---

**الخطوة 6️⃣: التحقق من الـ Indexes (1 دقيقة)**

✅ الملف: supabase/SETUP_QUERIES.sql (الجزء 8️⃣)

الخطوات:
1. نسخ هذا الكويري:

```sql
SELECT indexname FROM pg_indexes 
WHERE tablename IN ('safe_zones', 'location_updates', 'location_history', 'emergency_contacts')
ORDER BY indexname;
```

2. اضغط: "New Query"
3. الصق الكود
4. اضغط: Execute

✓ يجب تشوف: 10 indexes على الأقل

---

**الخطوة 7️⃣: اختبار الـ API (من التطبيق)**

✅ الملف: lib/core/tests/tracking_test_example.dart

الخطوات:
1. أضف في main.dart:

```dart
import 'lib/core/tests/tracking_test_example.dart';

void main() async {
  // ... initialization code ...
  
  // اختبر النظام
  await testTrackingSystem();
  
  runApp(const MyApp());
}
```

2. شغّل التطبيق
3. شوف الـ console للرسائل

✓ يجب تشوف رسائل النجاح:
```
✓ تم جلب X منطقة آمنة
✓ آخر موقع: ...
✓ تم جلب X سجل
✓ تم جلب X جهة اتصال
```

---

**الخطوة 8️⃣: دمج الـ Cubit في الشاشات**

✅ الملفات:
- lib/screens/patient/live_tracking/live_tracking_screen_example.dart
- lib/screens/family/tracking/family_tracking_screen_example.dart

الخطوات:
1. افتح الشاشة الحالية:
   lib/screens/patient/live_tracking_screen.dart

2. استبدل أو أضف هذا الكود:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/patient_tracking_cubit.dart';

@override
Widget build(BuildContext context) {
  return BlocProvider(
    create: (context) => PatientTrackingCubit(
      getIt<TrackingRepository>(),
      userId, // من session
    )..initializeTracking(),
    
    child: BlocBuilder<PatientTrackingCubit, PatientTrackingState>(
      builder: (context, state) {
        if (state.status == TrackingStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return Column(
          children: [
            // عرض الموقع
            Text('الموقع: ${state.address}'),
            
            // عرض حالة الأمان
            Text(
              state.isInsideSafeZone ? '✅ آمن' : '⚠️ خطر',
            ),
            
            // عرض المناطق الآمنة
            ListView.builder(
              itemCount: state.safeZones.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(state.safeZones[index].name),
                );
              },
            ),
          ],
        );
      },
    ),
  );
}
```

3. اعمل نفس الشيء للعائلة مع FamilyTrackingCubit

---

**الخطوة 9️⃣: اختبار شامل**

الخطوات:
1. شغّل التطبيق
2. تأكد من:
   ✅ يظهر الموقع الحالي
   ✅ المناطق الآمنة تظهر
   ✅ الأيقونة تتغير (آمن/خطر)
   ✅ السجل يظهر
   ✅ التحديثات تظهر فوريًا (كل 30 ثانية)

---

🎯 **ملخص الكويرز الأساسية:**

**1. جلب المناطق الآمنة:**
```sql
SELECT * FROM safe_zones 
WHERE patient_id = 'patient-id'
ORDER BY created_at DESC;
```

**2. جلب آخر موقع:**
```sql
SELECT * FROM location_updates 
WHERE patient_id = 'patient-id'
ORDER BY created_at DESC LIMIT 1;
```

**3. جلب السجل:**
```sql
SELECT * FROM location_history 
WHERE patient_id = 'patient-id'
AND arrived_at >= NOW() - INTERVAL '7 days'
ORDER BY arrived_at DESC;
```

**4. جلب جهات الطوارئ:**
```sql
SELECT * FROM emergency_contacts 
WHERE patient_id = 'patient-id'
ORDER BY is_primary DESC;
```

---

⏱️ **الوقت الإجمالي: ~20 دقيقة**

---

❓ **إذا حصل خطأ:**

❌ "Column does not exist"
→ تأكد من تطبيق Migration كاملاً

❌ "RLS policy violation"
→ استخدم patient_id الصحيح

❌ "Table does not exist"
→ أعد تطبيق Migration

❌ "Realtime not working"
→ تأكد من تطبيق ALTER PUBLICATION

---

✅ **انتهيت! يمكنك الآن:**

1. دمج الـ Cubit في الشاشات
2. اختبار التحديثات الفورية
3. إضافة مناطق جديدة
4. مراقبة الأمان

**النظام كامل وجاهز! 🚀**
