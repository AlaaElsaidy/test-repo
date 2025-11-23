# 🔍 **دليل تصحيح مشكلة عدم رفع البيانات على Supabase**

## الأسباب المحتملة:

### **1. ❌ لم تُعطِ الـ Permission للموقع**
```
الحل: وافق على "Allow Location Access" عند أول طلب
```

### **2. ❌ الـ GPS معطّل في الجهاز**
```
الحل: 
- اذهب لـ Settings
- Search for "Location"
- فعّل "Location Services"
```

### **3. ❌ الـ Supabase RLS Policies منع الإدراج**
```
الحل: فحص الـ RLS policies في Supabase
- الجدول: location_updates
- تأكد من إمكانية INSERT
```

### **4. ❌ الـ User ID غير صحيح**
```
الحل: تأكد من تسجيل الدخول الصحيح
```

---

## ✅ **الخطوات التشخيصية:**

### **الخطوة 1: استخدام أداة Debug**

1. استورد DebugLocationUploadScreen:
```dart
import 'core/tests/debug_location_upload.dart';
import 'core/repositories/tracking_repository.dart';
import 'core/di/injection_container.dart';
```

2. استخدمها بدل PatientTrackingScreen مؤقتاً:
```dart
// في main.dart أو في أي Route
DebugLocationUploadScreen(
  trackingRepository: getIt<TrackingRepository>(),
)
```

### **الخطوة 2: اضغط الأزرار بالترتيب:**

```
🟢 1️⃣ فحص Permission    → هل الـ permission موافق عليه؟
🟢 2️⃣ جلب الموقع       → هل GPS شغّال؟
🟢 3️⃣ اختبار الاتصال   → هل Supabase متصل؟
🔵 4️⃣ اختبار الرفع     → هل الرفع بينجح؟
🔵 5️⃣ فحص Database    → هل البيانات ظهرت؟
```

---

## 📊 **النتائج المتوقعة:**

### **✅ نجاح:**
```
🔐 الـ Permission الحالي: LocationPermission.whileInUse
✅ تم جلب الموقع:
   - Latitude: 30.0131
   - Longitude: 31.2089
   - Accuracy: 10.5
✅ الاتصال بـ location_updates ناجح
✅ تم الإرسال بنجاح!
   - ID: uuid-xxxx
✅ عدد السجلات: 5
   [0] 30.0131, 31.2089 @ 2025-11-23T...
```

### **❌ فشل + الحل:**
```
Permission Error:
❌ الـ Permission مرفوض
✅ الحل: وافق على Permission

Location Error:
❌ خطأ: تجاوز الوقت المحدد
✅ الحل: فعّل GPS أو انتظر في مكان مفتوح

Database Error:
❌ خطأ: FOREIGN KEY violation
✅ الحل: تأكد من user ID

Upload Error:
❌ خطأ: new row violates row-level security policy
✅ الحل: فحص RLS policies
```

---

## 🛠️ **فحص RLS Policies في Supabase:**

1. ادخل https://app.supabase.com
2. اختر `location_updates` جدول
3. اختر "RLS policies"
4. تأكد من وجود policy تسمح بـ INSERT

**Expected Policy:**
```sql
CREATE POLICY "users_insert_own_location"
ON location_updates
FOR INSERT
WITH CHECK (auth.uid() = patient_id)
```

---

## 💡 **إذا مفيش حل:**

### **التحقق من Supabase Config:**
```dart
// في lib/core/supabase/supabase-config.dart
print('URL: ${SupabaseConfig.supabaseUrl}');
print('Key: ${SupabaseConfig.supabaseKey.substring(0, 20)}...');
```

### **التحقق من الـ Imports:**
```dart
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
```

### **التحقق من pubspec.yaml:**
```yaml
dependencies:
  geolocator: ^10.1.0
  supabase_flutter: ^1.0.0
  geocoding: ^4.0.0
```

---

## 📱 **خطوات التشغيل الفعلي:**

```bash
# 1. تنظيف وإعادة build
flutter clean
flutter pub get

# 2. التشغيل
flutter run

# 3. اختبر أداة Debug
# اضغط الأزرار الخمسة بالترتيب
# شاهد النتائج في الـ logs

# 4. إذا نجح الاختبار
# استبدل DebugLocationUploadScreen بـ PatientTrackingScreen
```

---

## ✨ **الأداة توفر لك:**

- ✅ فحص الـ Permissions
- ✅ اختبار GPS
- ✅ اختبار الاتصال بـ Supabase
- ✅ اختبار رفع البيانات
- ✅ فحص البيانات المرفوعة
- ✅ رسائل خطأ واضحة
- ✅ Logs مفصلة في Console

---

## 🎯 **بعد إصلاح المشكلة:**

```
1. استخدم PatientTrackingScreen العادي
2. الموقع سيتحدث كل 5 ثواني
3. البيانات ستظهر في Supabase مباشرة
4. Real-time streams ستعمل
```

---

**نجاح! 🎉**
