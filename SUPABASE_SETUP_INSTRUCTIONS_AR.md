# خطوات نشر نظام التتبع على Supabase

## 1️⃣ التحقق من اتصالك بـ Supabase

```bash
# تحقق من أنك مسجل دخول بـ Supabase CLI
supabase status
```

إذا لم تكن مسجلاً دخول، استخدم:
```bash
supabase login
```

## 2️⃣ ربط مشروعك بـ Supabase Remote

```bash
# ابدأ من مجلد المشروع الرئيسي
cd e:\test repo alla\repootast\test-repo

# اربط مع مشروع Supabase الخاص بك
supabase link --project-ref xyhexdrr
```

> **ملاحظة**: استخدم الـ Project Reference ID الخاص بـ Supabase project:
> - المجلد: `supabase/config.toml`
> - البحث عن: `project_id = "test-repo"`

## 3️⃣ نشر الـ Migrations

```bash
# انشر جميع الـ migrations على الـ Supabase
supabase db push
```

هذا سيقوم بـ:
- ✅ إنشاء 4 جداول:
  - `safe_zones` - المناطق الآمنة
  - `location_updates` - تحديثات الموقع
  - `location_history` - السجل التاريخي للمواقع
  - `emergency_contacts` - جهات الاتصال الطارئة

- ✅ إنشاء 13 ندية (Row-Level Security Policies)
- ✅ إنشاء الـ Indexes للأداء الأفضل

## 4️⃣ التحقق من نجاح النشر

```bash
# شاهد حالة الـ migrations
supabase status

# أو ادخل إلى Supabase console وقم بـ inspect الجداول
# https://app.supabase.com
```

## 5️⃣ اختبار الاتصال من التطبيق

شغل اختبار الاتصال:
```bash
flutter run -t lib/core/tests/test_supabase_connection.dart
```

أو أضفه في `main.dart` مؤقتاً:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... initialization code ...
  
  // اختبار الاتصال
  await testSupabaseConnection();
  
  runApp(const MyApp());
}
```

## 6️⃣ إذا حصلت على أخطاء Permissions (RLS)

تحقق من:
1. **Authentication**: تأكد أنك مسجل دخول بـ Flutter app
2. **RLS Policies**: تأكد من أن الـ policies تسمح بـ access
3. **الـ User ID**: تأكد من أن `auth.uid()` يطابق الـ `patient_id`

## 7️⃣ قائمة التحقق النهائية

- [ ] Supabase مسجل دخول (`supabase login`)
- [ ] المشروع مرتبط (`supabase link`)
- [ ] الـ migrations منشورة (`supabase db push`)
- [ ] الجداول موجودة في Supabase console
- [ ] الـ RLS Policies صحيحة
- [ ] التطبيق يعمل بدون أخطاء permissions

---

## ملفات مهمة:

1. **ملف الـ SQL Migration**:
   - `supabase/migrations/20251122_create_tracking_tables.sql`

2. **ملف الكود الرئيسي للـ Tracking**:
   - `lib/core/repositories/tracking_repository.dart`
   - `lib/screens/patient/live_tracking/patient_tracking_screen.dart`
   - `lib/screens/family/tracking/family_tracking_screen.dart`

3. **الـ Configuration**:
   - `lib/core/supabase/supabase-config.dart`
   - `lib/core/di/injection_container.dart`

---

## مثال من Client Side (بعد النشر):

```dart
// هذا سيعمل بدون مشاكل بعد نشر الـ migrations
final zones = await trackingRepository.getSafeZones(patientId);
print('Zones: $zones'); // ستأتي البيانات من Supabase
```
