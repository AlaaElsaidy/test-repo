# نظام التتبع الديناميكي - دليل التنفيذ العملي

## ✅ ما تم إنجازه

### 1. **Models & Data Layer** ✓
- `lib/core/models/tracking_models.dart` - 4 classes كاملة:
  - `SafeZone` - المناطق الآمنة
  - `PatientLocation` - موقع المريض الحالي
  - `LocationHistory` - السجل التاريخي
  - `EmergencyContact` - جهات الاتصال الطوارئ

### 2. **Repository Pattern** ✓
- `lib/core/repositories/tracking_repository.dart` - جميع العمليات:
  - CRUD operations للمناطق والموقع والسجل
  - Real-time streams من Supabase
  - معالجة الأخطاء الكاملة

### 3. **Dependency Injection** ✓
- `lib/core/di/injection_container.dart` - تهيئة الخدمات
- `lib/main.dart` - دمج DI مع Supabase

### 4. **BLoC/Cubit للحالة** ✓
- `lib/screens/patient/live_tracking/cubit/` - PatientTrackingCubit
  - تتبع موقع المريض الفوري
  - إدارة المناطق الآمنة
  - تنبيهات حالة الأمان
  
- `lib/screens/family/tracking/cubit/` - FamilyTrackingCubit
  - مراقبة المريض من جانب الأهل
  - إحصائيات الزيارات
  - إدارة متقدمة للمناطق

### 5. **Utilities** ✓
- `lib/core/utils/location_utils.dart` - دوال محسوبة:
  - `calculateHaversineDistance()` - حساب المسافة
  - `isLocationInsideSafeZone()` - التحقق من الأمان
  - `findSafeZoneForLocation()` - تحديد المنطقة الحالية
  - تنسيق المسافات والسرعات

### 6. **Database Schema** ✓
- `supabase/migrations/20251122_create_tracking_tables.sql`:
  - 4 جداول مع RLS security
  - 13 سياسة أمان
  - 10 indexes للأداء

### 7. **UI Examples** ✓
- `lib/screens/patient/live_tracking/live_tracking_screen_example.dart`
- `lib/screens/family/tracking/family_tracking_screen_example.dart`

---

## 🚀 الخطوات التالية

### **الخطوة 1️⃣: تطبيق Migrations على Supabase**

1. اذهب إلى Supabase Console: https://app.supabase.com
2. اختر مشروعك
3. انسخ محتوى الملف: `supabase/migrations/20251122_create_tracking_tables.sql`
4. اذهب إلى **SQL Editor** → **New Query**
5. الصق الكود واضغط **Run**

✅ سيتم إنشاء:
- جدول `safe_zones`
- جدول `location_updates`
- جدول `location_history`
- جدول `emergency_contacts`
- جميع الـ RLS policies

---

### **الخطوة 2️⃣: تحديث شاشة المريض (Live Tracking)**

استبدل الكود القديم بـ Cubit:

```dart
// lib/screens/patient/live_tracking_screen.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/patient_tracking_cubit.dart';

@override
Widget build(BuildContext context) {
  return BlocProvider(
    create: (context) => PatientTrackingCubit(
      getIt<TrackingRepository>(),
      currentPatientId, // من user session
    )..initializeTracking(),
    child: BlocBuilder<PatientTrackingCubit, PatientTrackingState>(
      builder: (context, state) {
        if (state.status == TrackingStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state.status == TrackingStatus.error) {
          return ErrorWidget(message: state.errorMessage);
        }
        
        // عرض الموقع والمناطق الآمنة
        return Column(
          children: [
            // بطاقة الأمان
            SafetyStatusCard(
              isInside: state.isInsideSafeZone,
              currentZone: state.safeZones.firstWhere(
                (z) => _isInside(state.currentPosition!, z),
                orElse: () => null,
              ),
            ),
            
            // خريطة الموقع
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  state.currentPosition?.latitude ?? 0,
                  state.currentPosition?.longitude ?? 0,
                ),
                zoom: 15,
              ),
              markers: {
                // إضافة marker للموقع الحالي
                Marker(
                  markerId: const MarkerId('current'),
                  position: LatLng(
                    state.currentPosition?.latitude ?? 0,
                    state.currentPosition?.longitude ?? 0,
                  ),
                ),
                // إضافة markers للمناطق الآمنة
                ...state.safeZones.map((zone) => Marker(
                  markerId: MarkerId('zone_${zone.id}'),
                  position: LatLng(zone.latitude, zone.longitude),
                )),
              },
              circles: state.safeZones
                  .asMap()
                  .entries
                  .map((e) => Circle(
                    circleId: CircleId('zone_${e.value.id}'),
                    center: LatLng(e.value.latitude, e.value.longitude),
                    radius: e.value.radiusMeters.toDouble(),
                    fillColor: Colors.blue.withOpacity(0.1),
                    strokeColor: Colors.blue,
                  ))
                  .toSet(),
            ),
            
            // قائمة المناطق الآمنة
            SafeZonesList(
              zones: state.safeZones,
              onToggle: (zoneId, isActive) {
                context.read<PatientTrackingCubit>()
                    .toggleSafeZone(zoneId, isActive);
              },
              onAdd: () {
                // فتح dialog لإضافة منطقة جديدة
              },
            ),
          ],
        );
      },
    ),
  );
}
```

---

### **الخطوة 3️⃣: تحديث شاشة العائلة (Family Tracking)**

```dart
// lib/screens/family/family_tracking_screen.dart

import 'cubit/family_tracking_cubit.dart';

@override
Widget build(BuildContext context) {
  return BlocProvider(
    create: (context) => FamilyTrackingCubit(
      getIt<TrackingRepository>(),
      selectedPatientId, // المريض المختار
    )..initializeTracking(),
    child: BlocBuilder<FamilyTrackingCubit, FamilyTrackingState>(
      builder: (context, state) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.location_on), text: 'حي'),
                  Tab(icon: Icon(Icons.safety_divider), text: 'المناطق'),
                  Tab(icon: Icon(Icons.history), text: 'السجل'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // التبويب الأول: البث المباشر
                _LiveTrackingTab(state),
                
                // التبويب الثاني: المناطق الآمنة
                _SafeZonesTab(state, context),
                
                // التبويب الثالث: السجل التاريخي
                _HistoryTab(state),
              ],
            ),
          ),
        );
      },
    ),
  );
}
```

---

### **الخطوة 4️⃣: إضافة صلاحيات الموقع في Android**

✏️ **android/app/src/main/AndroidManifest.xml**:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

✏️ **android/app/build.gradle**:
```gradle
android {
  compileSdkVersion 34
  
  defaultConfig {
    targetSdkVersion 34
    minSdkVersion 21
  }
}
```

---

### **الخطوة 5️⃣: إضافة صلاحيات الموقع في iOS**

✏️ **ios/Runner/Info.plist**:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>نحتاج إلى موقعك للتتبع الآمن</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>نحتاج إلى موقعك للتتبع حتى عندما يكون التطبيق مغلقًا</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>نحتاج إلى موقعك للتتبع المستمر</string>
```

---

### **الخطوة 6️⃣: اختبار النظام**

```dart
// في main.dart أو screen test

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة عادية
  await SupabaseConfig.initialize();
  setupDependencies();
  
  // اختبار بسيط
  final repo = getIt<TrackingRepository>();
  
  // 1. جلب المناطق الآمنة
  final zones = await repo.getSafeZones('patient-id');
  print('Found ${zones.length} safe zones');
  
  // 2. جلب آخر موقع
  final location = await repo.getLastLocation('patient-id');
  print('Last location: ${location?.address}');
  
  // 3. مراقبة تحديثات الموقع
  repo.watchLocationUpdates('patient-id').listen((location) {
    print('Location update: ${location.address}');
  });
  
  runApp(const MyApp());
}
```

---

## 📊 تدفق البيانات

```
┌─────────────────────────────────────────────────┐
│          User Location (Geolocator)             │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│       PatientTrackingCubit (تحديث كل 30ث)       │
│  - حساب الموقع الحالي                           │
│  - التحقق من المنطقة الآمنة                    │
│  - إرسال للـ Database                          │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│    Supabase location_updates table              │
│    ┌─────────────────────────────────┐          │
│    │ id, patient_id, lat, lng,       │          │
│    │ address, accuracy, timestamp    │          │
│    └─────────────────────────────────┘          │
└────────────────┬────────────────────────────────┘
                 │
    ┌────────────┴────────────┐
    │                         │
    ▼                         ▼
┌─────────────────────┐ ┌──────────────────┐
│ Real-time Stream   │ │ Location History │
│ (لـ Family Watch)   │ │ (تسجيل يومي)    │
└─────────────────────┘ └──────────────────┘
    │
    ▼
┌──────────────────────────┐
│ FamilyTrackingCubit      │
│ - عرض الموقع الحي        │
│ - إدارة المناطق الآمنة   │
│ - إحصائيات الزيارات     │
└──────────────────────────┘
    │
    ▼
┌──────────────────────────┐
│ UI - Family Screen       │
│ - 3 Tabs                 │
│ - Live, Zones, History   │
└──────────────────────────┘
```

---

## 🔐 الأمان

### RLS (Row-Level Security) Policies

✅ **Safe Zones**: 
- المريض يرى مناطقه فقط
- الطبيب والعائلة يرون مناطق المريض المسند لهم

✅ **Location Updates**:
- فقط المريض يستطيع الكتابة
- الأهل والطبيب يرون فقط

✅ **Location History**:
- فقط المريض يستطيع الكتابة والتعديل
- الأهل والطبيب يرون فقط

---

## 📱 المميزات المتاحة

### للمريض (Patient):
- ✅ عرض موقعي الحالي
- ✅ إضافة/حذف مناطق آمنة
- ✅ تشغيل/إيقاف المراقبة
- ✅ عرض السجل التاريخي
- ✅ إدارة جهات الطوارئ

### للأهل (Family):
- ✅ مراقبة موقع المريض حيًا
- ✅ رؤية حالة الأمان (داخل/خارج)
- ✅ إضافة/تعديل المناطق الآمنة
- ✅ عرض إحصائيات الزيارات
- ✅ مراجعة السجل التاريخي

### للطبيب (Doctor):
- ✅ مراقبة أنماط الحركة
- ✅ معرفة الأماكن المعتادة
- ✅ تقييم النشاط البدني

---

## 🐛 استكشاف الأخطاء

### المشكلة: لا يتم تحديث الموقع
```dart
// تحقق من صلاحيات الموقع
final permission = await Geolocator.checkPermission();
if (permission != LocationPermission.whileInUse && 
    permission != LocationPermission.always) {
  // اطلب الصلاحيات
  await Geolocator.requestPermission();
}
```

### المشكلة: الـ Realtime لا يعمل
```dart
// تحقق من الاتصال
final status = await Supabase.instance.client.auth.session();
if (status == null) {
  // أعد تسجيل الدخول
}
```

### المشكلة: خطأ في RLS
```
Error: new row violates row-level security policy
```
- تحقق من أن `user_id` في JWT يطابق المستخدم
- تأكد من وجود السجل في `safe_zones` مع `patient_id` الصحيح

---

## 📞 الدعم والمساعدة

إذا واجهت أي مشاكل:
1. تحقق من أن Migrations تم تطبيقها بنجاح
2. تأكد من أن جميع الصلاحيات مُعطاة
3. اختبر الـ API مباشرة في Supabase Console
4. تحقق من أخطاء الـ RLS في Logs

---

**آخر تحديث: November 23, 2025**
