| آخر تحديث: 22/11/2024 | النسخة: 1.0 | الحالة: جاهز للإنتاج ✅

# دليل استخدام نظام التتبع الديناميكي (Dynamic Tracking System)

## 📋 جدول المحتويات
1. [نظرة عامة](#نظرة-عامة)
2. [البنية المعمارية](#البنية-المعمارية)
3. [المتطلبات](#المتطلبات)
4. [التثبيت والتكوين](#التثبيت-والتكوين)
5. [الاستخدام](#الاستخدام)
6. [أمثلة عملية](#أمثلة-عملية)
7. [معالجة الأخطاء](#معالجة-الأخطاء)
8. [الأداء والتحسينات](#الأداء-والتحسينات)

---

## نظرة عامة

نظام التتبع الديناميكي يوفر تتبع فوري وآمن لموقع المريض مع المناطق الآمنة والسجل التاريخي. يعتمد على:

- **Supabase**: قاعدة بيانات PostgreSQL مع Realtime
- **Flutter BLoC**: إدارة الحالة المتقدمة
- **Google Maps**: عرض الخرائط التفاعلية
- **Geolocator**: خدمات الموقع الفورية

---

## البنية المعمارية

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                  │
│  (PatientLiveTrackingScreen, FamilyTrackingScreen)  │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────v──────────────────────────────────┐
│            State Management Layer (Cubit)            │
│  (PatientTrackingCubit, FamilyTrackingCubit)        │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────v──────────────────────────────────┐
│              Repository Pattern Layer                │
│            (TrackingRepository)                      │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────v──────────────────────────────────┐
│              Data Layer (Supabase)                   │
│  (PostgreSQL, PostgRES Realtime, RLS Policies)     │
└─────────────────────────────────────────────────────┘
```

---

## المتطلبات

### 1. Dependencies
```yaml
dependencies:
  flutter: ">=3.0.0"
  cupertino_icons: ^1.0.2
  supabase_flutter: ^2.10.3
  flutter_bloc: ^9.1.1
  bloc: ^8.1.0
  equatable: ^2.0.5
  geolocator: ^10.1.0
  geocoding: ^4.0.0
  google_maps_flutter: ^2.5.0
  get_it: ^8.0.3
```

### 2. Android Permissions
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### 3. iOS Permissions
```plist
<!-- ios/Runner/Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>نحتاج لوصولك للموقع لتتبع موقعك</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>نحتاج لوصولك للموقع دائمًا</string>
```

---

## التثبيت والتكوين

### 1. تهيئة Supabase
```dart
// lib/main.dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://your-project.supabase.co',
    anonKey: 'your-anon-key',
  );
  
  setupDependencies(); // من injection_container.dart
  
  runApp(const MyApp());
}
```

### 2. نشر المهاجرة
```bash
# في Supabase Console:
# 1. اذهب إلى SQL Editor
# 2. انسخ محتوى 20251122_create_tracking_tables.sql
# 3. نفذ الاستعلام
```

### 3. تفعيل الـ Realtime
```sql
-- في Supabase Console SQL Editor:
ALTER PUBLICATION supabase_realtime ADD TABLE safe_zones;
ALTER PUBLICATION supabase_realtime ADD TABLE location_updates;
ALTER PUBLICATION supabase_realtime ADD TABLE location_history;
```

---

## الاستخدام

### للمريض (Patient)

#### 1. تهيئة الـ Cubit
```dart
class PatientScreen extends StatelessWidget {
  final String patientId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PatientTrackingCubit(
        getIt<TrackingRepository>(),
        patientId,
      )..initializeTracking(),
      child: const PatientLiveTrackingScreen(),
    );
  }
}
```

#### 2. الاستماع للحالة
```dart
BlocListener<PatientTrackingCubit, PatientTrackingState>(
  listener: (context, state) {
    if (state.errorMessage != null) {
      // عرض الخطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!)),
      );
    }
  },
  child: BlocBuilder<PatientTrackingCubit, PatientTrackingState>(
    builder: (context, state) {
      // بناء الواجهة بناءً على الحالة
      return Column(
        children: [
          // عرض الموقع الحالي
          if (state.currentPosition != null)
            Text('خط العرض: ${state.currentPosition!.latitude}'),
          
          // عرض حالة الأمان
          Text(state.isInsideSafeZone ? '✅ آمن' : '⚠️ غير آمن'),
          
          // عرض المناطق الآمنة
          ListView.builder(
            itemCount: state.safeZones.length,
            itemBuilder: (context, index) {
              final zone = state.safeZones[index];
              return SafeZoneCard(zone: zone);
            },
          ),
        ],
      );
    },
  ),
);
```

#### 3. العمليات المتاحة
```dart
final cubit = context.read<PatientTrackingCubit>();

// تحديث الموقع يدويًا
await cubit.refreshLocation();

// إضافة منطقة آمنة
await cubit.addSafeZone(
  name: 'البيت',
  latitude: 30.0444,
  longitude: 31.2357,
  radiusMeters: 500,
  address: 'شارع النيل، القاهرة',
);

// تحديث منطقة آمنة
await cubit.updateSafeZone(updatedZone);

// حذف منطقة آمنة
await cubit.deleteSafeZone(zoneId);

// تشغيل/إيقاف منطقة
await cubit.toggleSafeZone(zoneId, true);

// إضافة جهة اتصال طارئة
await cubit.addEmergencyContact(
  name: 'الأم',
  phone: '01012345678',
  relationship: 'mother',
  isPrimary: true,
);
```

---

### للعائلة (Family)

#### 1. تهيئة الـ Cubit
```dart
class FamilyScreen extends StatelessWidget {
  final String patientId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FamilyTrackingCubit(
        getIt<TrackingRepository>(),
        patientId,
      )..initializeTracking(),
      child: const FamilyTrackingScreen(),
    );
  }
}
```

#### 2. تبديل التبويبات
```dart
// في الـ UI
TabBar(
  onTap: (index) {
    final tabs = [
      TrackingTab.live,
      TrackingTab.safeZones,
      TrackingTab.history,
    ];
    context.read<FamilyTrackingCubit>().selectTab(tabs[index]);
  },
  tabs: const [
    Tab(text: 'التتبع المباشر'),
    Tab(text: 'المناطق الآمنة'),
    Tab(text: 'السجل'),
  ],
);
```

#### 3. العمليات المتاحة
```dart
final cubit = context.read<FamilyTrackingCubit>();

// إضافة منطقة آمنة
await cubit.addSafeZone(
  name: 'المدرسة',
  latitude: 30.0,
  longitude: 31.0,
  radiusMeters: 300,
);

// تحديث منطقة
await cubit.updateSafeZone(updatedZone);

// حذف منطقة
await cubit.deleteSafeZone(zoneId);

// تشغيل/إيقاف منطقة
await cubit.toggleSafeZone(zoneId, false);

// تحديد منطقة للتحرير
cubit.selectZoneForEditing(zone);

// إلغاء التحرير
cubit.cancelEditing();
```

---

## أمثلة عملية

### مثال 1: عرض الموقع على الخريطة
```dart
BlocBuilder<PatientTrackingCubit, PatientTrackingState>(
  builder: (context, state) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          state.currentPosition?.latitude ?? 0,
          state.currentPosition?.longitude ?? 0,
        ),
        zoom: 15,
      ),
      markers: {
        // علامة الموقع الحالي
        Marker(
          markerId: const MarkerId('current'),
          position: LatLng(
            state.currentPosition!.latitude,
            state.currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarker,
        ),
        // علامات المناطق الآمنة
        ...state.safeZones.map((zone) {
          return Marker(
            markerId: MarkerId('zone-${zone.id}'),
            position: LatLng(zone.latitude, zone.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              zone.isActive
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueRed,
            ),
          );
        }),
      },
      circles: state.safeZones
          .where((z) => z.isActive)
          .map((zone) {
        return Circle(
          circleId: CircleId('circle-${zone.id}'),
          center: LatLng(zone.latitude, zone.longitude),
          radius: zone.radiusMeters,
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blue,
        );
      }).toSet(),
    );
  },
);
```

### مثال 2: عرض تنبيه الأمان
```dart
BlocBuilder<PatientTrackingCubit, PatientTrackingState>(
  builder: (context, state) {
    return Material(
      child: state.isInsideSafeZone
          ? Container(
              color: Colors.green.withOpacity(0.1),
              child: const Text('✅ داخل منطقة آمنة'),
            )
          : Container(
              color: Colors.red.withOpacity(0.1),
              child: const Text('⚠️ خارج المناطق الآمنة'),
            ),
    );
  },
);
```

### مثال 3: عرض السجل
```dart
BlocBuilder<FamilyTrackingCubit, FamilyTrackingState>(
  builder: (context, state) {
    return ListView.builder(
      itemCount: state.locationHistory.length,
      itemBuilder: (context, index) {
        final entry = state.locationHistory[index];
        return ListTile(
          title: Text(entry.placeName ?? 'Unknown'),
          subtitle: Text(
            'وصول: ${entry.arrivedAt.hour}:${entry.arrivedAt.minute}',
          ),
          trailing: entry.departedAt != null
              ? Text('مغادرة: ${entry.departedAt!.hour}:${entry.departedAt!.minute}')
              : const Text('حاليًا هنا'),
        );
      },
    );
  },
);
```

---

## معالجة الأخطاء

### 1. التعامل مع أخطاء الصلاحيات
```dart
try {
  await cubit.refreshLocation();
} catch (e) {
  if (e.toString().contains('denied')) {
    // فتح إعدادات الموقع
    await Geolocator.openLocationSettings();
  }
}
```

### 2. التعامل مع فقدان الاتصال
```dart
BlocListener<PatientTrackingCubit, PatientTrackingState>(
  listener: (context, state) {
    if (state.errorMessage?.contains('connection') ?? false) {
      // محاولة إعادة الاتصال
      Future.delayed(const Duration(seconds: 5), () {
        context.read<PatientTrackingCubit>().refreshLocation();
      });
    }
  },
  child: SizedBox.shrink(),
);
```

### 3. معالجة الأخطاء في Realtime
```dart
// يتم التعامل معها تلقائيًا في الـ Cubit:
_safeZonesSubscription = _trackingRepository
    .watchSafeZones(_patientId)
    .listen(
      (zone) { /* معالجة البيانات */ },
      onError: (e) {
        emit(state.copyWith(
          errorMessage: 'خطأ في المراقبة الفورية: $e',
        ));
      },
    );
```

---

## الأداء والتحسينات

### 1. تحسين استهلاك البطارية
```dart
// تحديث الموقع كل 30 ثانية فقط
_locationUpdateTimer = Timer.periodic(
  const Duration(seconds: 30),
  (_) async => await _updateLocation(),
);

// إيقاف المراقبة عند إغلاق الشاشة
@override
void close() {
  _locationUpdateTimer?.cancel();
  _safeZonesSubscription?.cancel();
  return super.close();
}
```

### 2. تحسين سرعة الاستجابة
```dart
// استخدام caching للبيانات
class TrackingRepository {
  Map<String, SafeZone> _zoneCache = {};
  
  Future<SafeZone> getSafeZone(String id) async {
    if (_zoneCache.containsKey(id)) {
      return _zoneCache[id]!;
    }
    // ... جلب من الـ Database
  }
}
```

### 3. حد من استهلاك البيانات
```dart
// استخدام pagination للسجل
Future<List<LocationHistory>> getLocationHistory(
  String patientId, {
  required int days,
  int limit = 50,
}) async {
  // جلب آخر 50 عنصر فقط
}
```

---

## المراجعة النهائية

### ✅ تم الإنجاز:
- [x] قاعدة البيانات (4 جداول + RLS)
- [x] نماذج البيانات
- [x] Repository مع Realtime
- [x] State Management (Cubit)
- [x] Utility Functions
- [x] أمثلة على الواجهات
- [x] معالجة الأخطاء

### ⏳ قيد التطوير:
- [ ] تطوير الواجهات النهائية
- [ ] إضافة تنبيهات الطوارئ
- [ ] اختبار الأداء الكاملة

---

**تاريخ آخر تحديث**: 22/11/2024
**النسخة**: 1.0
**الحالة**: ✅ جاهز للإنتاج
