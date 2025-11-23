# 📍 تحليل شامل لنظام التتبع - Patient & Relative

## 🎯 الفهرس
1. [المشكلة الحالية](#المشكلة-الحالية)
2. [تحليل الكود للمريض](#تحليل-الكود-للمريض-patient)
3. [تحليل الكود للقريب](#تحليل-الكود-للقريب-relative-family)
4. [تحليل الكود للطبيب](#تحليل-الكود-للطبيب-doctor)
5. [المنطق الحالي (Static)](#المنطق-الحالي--static)
6. [كيفية تحويلها لديناميكية](#كيفية-تحويلها-لديناميكية)
7. [الخطة التقنية للتحديث](#الخطة-التقنية-للتحديث)

---

## ❌ المشكلة الحالية

### الوضع الراهن (Hard-coded / Static):
جميع بيانات التتبع **مكتوبة بشكل ثابت** في الكود:
- ✗ المواقع الآمنة (Safe Zones) مُحفوظة بأرقام ثابتة
- ✗ موقع المريض الحالي static (لا يتغير إلا عند Refresh يدوي)
- ✗ لا يوجد اتصال بـ Database أو API
- ✗ التاريخ (History) مكتوب يدويًا
- ✗ لا يوجد تحديث فوري (Real-time Updates)
- ✗ عند إغلاق التطبيق، تُفقد جميع التعديلات

---

## 📱 تحليل الكود للمريض (Patient)

### الملف: `lib/screens/patient/live_tracking_screen.dart`

#### 🔴 **الحالة الحالية (Static)**

```dart
class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  // 1️⃣ بيانات المريض
  Position? _pos;              // الموقع الحالي (يتم جلبه مرة واحدة)
  DateTime? _lastUpdated;      // آخر تحديث
  String? _address;            // العنوان (جيو-كود معكوس)

  // 2️⃣ المناطق الآمنة - **ثابتة ومكتوبة بالكود**
  final List<_SafeZone> _safeZones = const [
    _SafeZone(
      name: 'Home',
      lat: 31.034350,
      lng: 30.471819,
      radiusMeters: 20,
      isActive: true,
    ),
  ];

  // 3️⃣ رقم الطوارئ - **محكوم بالكود**
  final String _emergencyPhone = '+201210402952';
}
```

#### 📋 **الشاشة الرئيسية للمريض**

| القسم | الغرض | الحالة |
|------|-------|--------|
| **Map Display** | عرض مؤشر دائري بسيط | Static illustration |
| **Status Badge** | 🟢 Safe / 🔴 Outside | يتعتمد على `_insideAnyZone` |
| **Location Info** | عنوان + آخر تحديث | يتم جلبه بـ Geolocator |
| **Refresh Button** | تحديث الموقع يدويًا | يدوي فقط |
| **Emergency Alert** | إرسال SOS | يدويًا عبر WhatsApp/SMS |

#### 🔧 **المنطق الحالي:**

```dart
// 1. جلب الموقع عند بدء الشاشة
@override
void initState() {
  super.initState();
  _getCurrentLocation(); // يحدث **مرة واحدة فقط**
}

// 2. حساب الأمان
bool get _insideAnyZone {
  if (_pos == null) return true;
  for (final z in _safeZones) {
    if (!z.isActive) continue;
    // حساب المسافة بـ Haversine
    final d = _distanceMeters(_pos!.latitude, _pos!.longitude, z.lat, z.lng);
    if (d <= z.radiusMeters) return true; // في منطقة آمنة ✅
  }
  return false; // خارج المنطقة ❌
}

// 3. التحديث اليدوي فقط
Future<void> _getCurrentLocation() async {
  // طلب الصلاحيات
  // جلب الموقع الحالي بـ Geolocator
  // عكس الجيو-كود (Reverse Geocoding) بـ geocoding package
}
```

#### ❌ **المشاكل:**
1. **لا توجد ساعة تحديث تلقائية (Timer)** - الموقع يُجلب مرة واحدة فقط
2. **المناطق الآمنة ثابتة** - لا يمكن إضافة أو تعديل مناطق جديدة
3. **لا يوجد اتصال بـ Backend** - البيانات محلية فقط
4. **Emergency contact محكوم بالكود** - لا يمكن تغييره ديناميكيًا

---

## 👨‍👩‍👧 تحليل الكود للقريب (Relative / Family)

### الملف: `lib/screens/family/family_tracking_screen.dart`

#### 🔴 **الحالة الحالية (Static)**

```dart
class _FamilyTrackingScreenState extends State<FamilyTrackingScreen> {
  // 1️⃣ اسم المريض - ثابت
  final String _patientName = 'Margaret Smith';

  // 2️⃣ موقع المريض - ثابت ومحدد يدويًا
  _LatLng _patient = const _LatLng(31.041243, 30.465516);
  DateTime _lastUpdated = DateTime.now();

  // 3️⃣ المناطق الآمنة - **4 مناطق مكتوبة بالكود**
  final List<_SafeZone> _safeZones = [
    _SafeZone(
      name: 'Home',
      address: '123 mostashfa Street, damanhour',
      lat: 31.041243,
      lng: 30.465516,
      radiusMeters: 200,
      isActive: true,
    ),
    _SafeZone(name: 'Park', ...),
    _SafeZone(name: 'Hospital', ...),
    _SafeZone(name: 'Church', ...),
  ];

  // 4️⃣ السجل - **4 مدخلات ثابتة**
  final List<_HistoryEntry> _history = [
    _HistoryEntry(place: 'Home', ..., lat: 31.041243, lng: 30.465516),
    _HistoryEntry(place: 'Park', ...),
    // ...
  ];
}
```

#### 📋 **الشاشة الرئيسية للقريب - 3 Tabs**

| رقم Tab | الاسم | الغرض | الحالة |
|--------|------|-------|--------|
| 0 | **Live** | عرض موقع المريض الفوري | Static map illustration |
| 1 | **Safe Zones** | إدارة المناطق الآمنة | محرر في الذاكرة (في session فقط) |
| 2 | **History** | سجل الحركة | Static data |

#### 🔍 **Tab 0: Live Tracking**

```dart
// عرض:
// - خريطة توضيحية (ليست خريطة حقيقية)
// - حالة (Safe/Outside)
// - العنوان (مكتوب بالكود)
// - آخر تحديث (وقت محدد)
// - زر "Get Directions to Patient"
// - زر Refresh (يحاكي الحركة العشوائية)

void _refreshLocation() {
  // محاكاة حركة صغيرة عشوائية
  final r = Random();
  final deltaLat = (r.nextDouble() - 0.5) / 5000; // حركة عشوائية صغيرة جدًا
  final deltaLng = (r.nextDouble() - 0.5) / 5000;
  setState(() {
    _patient = _LatLng(_patient.lat + deltaLat, _patient.lng + deltaLng);
    _lastUpdated = DateTime.now();
  });
}
```

#### 🔧 **Tab 1: Safe Zones Editor**

```dart
// قابل للتعديل في الجلسة الحالية:
// ✅ تشغيل/إيقاف منطقة (Toggle)
// ✅ حذف منطقة (Delete)
// ✅ إضافة منطقة جديدة (Add) - بـ Modal Sheet

void _openAddSafeZoneSheet({
  required void Function(_SafeZone) onAdd,
}) {
  // يسمح بإدخال:
  // - الاسم
  // - العنوان
  // - الإحداثيات (lat/lng)
  // - نصف القطر (radius) بـ Slider
  // - تشغيل/إيقاف
  
  // ⚠️ المشكلة: التعديلات **تُحفظ فقط في الذاكرة**
  // عند إغلاق التطبيق → تُفقد جميع التعديلات
}
```

#### 📜 **Tab 2: History**

```dart
// عرض سجل الحركة:
// - 4 مدخلات ثابتة مكتوبة بالكود
// - مكان، عنوان، وقت، مدة الإقامة
// - زر "Directions" لكل مدخل
```

#### ❌ **المشاكل:**
1. **موقع المريض ثابت** - يُحدث عشوائيًا فقط عند الضغط على Refresh
2. **لا يوجد اتصال Backend** - البيانات محلية وتُفقد عند إغلاق التطبيق
3. **التعديلات غير محفوظة** - تُعدَّل في الذاكرة فقط (Session state)
4. **السجل ثابت** - لا يتم تسجيل الحركة الفعلية للمريض
5. **لا توجد تحديثات فورية** - يجب الضغط على Refresh يدويًا

---

## 👨‍⚕️ تحليل الكود للطبيب (Doctor)

### الملف: `lib/screens/doctor/doctor_tracking_screen.dart`

#### 🔴 **الحالة الحالية (Static)**

```dart
class _DoctorTrackingScreenState extends State<DoctorTrackingScreen> {
  int _selectedIndex = 0; // تحديد المريض من القائمة

  // **3 مرضى مكتوبين بالكود**
  late final List<_Patient> _patients = [
    _Patient(
      name: 'Margaret Smith',
      locationLabel: 'At Home',
      position: const _LatLng(37.3318, -122.0312),
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
      safeZones: [
        _SafeZone(name: 'Home', address: '123 Oak Street, Springfield', ...),
        _SafeZone(name: 'Park', ...),
        _SafeZone(name: 'Hospital', ...),
      ],
      history: [
        _HistoryEntry(place: 'Home', ...),
        _HistoryEntry(place: 'Park', ...),
      ],
    ),
    _Patient(name: 'John Davis', ...),
    _Patient(name: 'Mary Taylor', ...),
  ];
}
```

#### 📋 **الشاشة الرئيسية للطبيب**

```
┌─────────────────────────────────────┐
│  Dropdown: Select Patient [Margaret Smith ▼]
├─────────────────────────────────────┤
│  Map Display (Static)               │
│  Status Badge: 🟢 Safe Zone         │
├─────────────────────────────────────┤
│  📍 Current Location: At Home        │
│     123 Oak Street, Springfield    │
│     Last updated: 2 mins ago       │
│     [🔄 Refresh] [🗺️ Directions]   │
├─────────────────────────────────────┤
│  ⚙️ Edit Safe Zones [Opens Modal]  │
│  📜 View History [Shows Entries]   │
└─────────────────────────────────────┘
```

#### 🔧 **المنطق الحالي:**

```dart
// 1. اختيار المريض من Dropdown
int _selectedIndex = 0;

// 2. جلب المريض الحالي
_Patient get _currentPatient => _patients[_selectedIndex];

// 3. حساب الأمان
bool _isSafe(_Patient p) =>
    p.safeZones.any((z) => _isInsideZone(p.position, z));

// 4. Refresh (محاكاة حركة عشوائية)
void _refreshSelected() {
  final r = Random();
  final p = _patients[_selectedIndex];
  final deltaLat = (r.nextDouble() - 0.5) / 5000;
  final deltaLng = (r.nextDouble() - 0.5) / 5000;
  setState(() {
    _patients[_selectedIndex] = p.copyWith(
      position: _LatLng(p.position.lat + deltaLat, p.position.lng + deltaLng),
      lastUpdated: DateTime.now(),
    );
  });
}

// 5. فتح محرر Safe Zones
void _openAddSafeZoneSheet() { /* محرر ديناميكي في Modal */ }

// 6. فتح سجل الحركة
void _openHistorySheet(_Patient p) { /* عرض History */ }
```

#### ❌ **المشاكل:**
1. **قائمة المرضى ثابتة** - 3 مرضى فقط مكتوبين بالكود
2. **لا يوجد اتصال Backend** - لا تحديث فوري من Server
3. **التعديلات غير محفوظة** - تُعدَّل في الذاكرة فقط
4. **لا يوجد تحديثات فورية** - يجب refresh يدويًا
5. **السجل ثابت** - لا يتم تسجيل الحركة الفعلية

---

## 📊 المنطق الحالي (Static)

### جدول المقارنة بين الثلاث شاشات:

| الميزة | Patient | Family | Doctor |
|------|---------|--------|--------|
| **عدد المرضى/المراقبين** | 1 (نفس المريض) | 1 مريض | 3 مرضى |
| **مصدر البيانات** | Hard-coded | Hard-coded | Hard-coded |
| **تحديث الموقع** | مرة واحدة (initState) | عشوائي (Refresh يدويًا) | عشوائي (Refresh يدويًا) |
| **تعديل Safe Zones** | ❌ غير ممكن | ✅ ممكن (Session) | ✅ ممكن (Session) |
| **حفظ التعديلات** | ❌ | ❌ (في الذاكرة فقط) | ❌ (في الذاكرة فقط) |
| **إضافة Zones جديدة** | ❌ | ✅ ديناميكيًا (Session) | ✅ ديناميكيًا (Session) |
| **السجل (History)** | ❌ | ✅ (Static 4 entries) | ✅ (Static 2-3 entries) |
| **Emergency Contact** | Hard-coded | ❌ | ❌ |
| **اتصال Backend** | ❌ | ❌ | ❌ |
| **Real-time Updates** | ❌ | ❌ | ❌ |

---

## ✅ كيفية تحويلها لديناميكية

### 🎯 الهدف النهائي:
```
Static (Hard-coded) → Dynamic (API/Database)
┌──────────────────┐       ┌─────────────┐       ┌──────────────┐
│  Mobile App      │◄─────►│  Backend    │◄─────►│  Database    │
│                  │       │  Server     │       │  (Supabase)  │
│ - Patient        │       │             │       │              │
│ - Family         │       │ - APIs      │       │ - Users      │
│ - Doctor         │       │ - Real-time │       │ - Locations  │
│                  │       │ - WebSocket │       │ - SafeZones  │
└──────────────────┘       └─────────────┘       │ - History    │
                                                 └──────────────┘
```

---

## 🔄 الخطة التقنية للتحديث

### **المرحلة 1: إنشاء Models وRepositories**

#### 1.1 إنشاء Models:

```dart
// lib/core/models/tracking_models.dart

// 1. نموذج Safe Zone
class SafeZone {
  final String id;                    // UUID من Database
  final String patientId;             // ربط المريض
  final String name;                  // 'Home', 'Park'
  final String address;               // '123 Oak Street'
  final double lat;
  final double lng;
  final double radiusMeters;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SafeZone({
    required this.id,
    required this.patientId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // تحويل من JSON (من API)
  factory SafeZone.fromJson(Map<String, dynamic> json) => SafeZone(
    id: json['id'],
    patientId: json['patient_id'],
    name: json['name'],
    address: json['address'] ?? '—',
    lat: (json['latitude'] as num).toDouble(),
    lng: (json['longitude'] as num).toDouble(),
    radiusMeters: (json['radius_meters'] as num).toDouble(),
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  // تحويل إلى JSON (لإرسال للـ API)
  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'name': name,
    'address': address,
    'latitude': lat,
    'longitude': lng,
    'radius_meters': radiusMeters,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  // نسخة مع تحديثات
  SafeZone copyWith({
    String? id,
    String? patientId,
    String? name,
    String? address,
    double? lat,
    double? lng,
    double? radiusMeters,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SafeZone(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    name: name ?? this.name,
    address: address ?? this.address,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    radiusMeters: radiusMeters ?? this.radiusMeters,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

// 2. نموذج موقع المريض
class PatientLocation {
  final String id;                    // UUID
  final String patientId;             // ربط المريض
  final double latitude;
  final double longitude;
  final String? address;              // العنوان (جيو-كود معكوس)
  final double? accuracy;             // دقة GPS بالمتر
  final DateTime timestamp;           // وقت القياس

  PatientLocation({
    required this.id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    this.address,
    this.accuracy,
    required this.timestamp,
  });

  factory PatientLocation.fromJson(Map<String, dynamic> json) => PatientLocation(
    id: json['id'],
    patientId: json['patient_id'],
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    address: json['address'],
    accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
    timestamp: DateTime.parse(json['timestamp']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'accuracy': accuracy,
    'timestamp': timestamp.toIso8601String(),
  };
}

// 3. نموذج السجل
class LocationHistory {
  final String id;
  final String patientId;
  final String placeName;            // 'Home', 'Park'
  final String address;
  final double latitude;
  final double longitude;
  final DateTime arrivedAt;
  final DateTime? departedAt;        // null إذا لم يغادر بعد
  final Duration? duration;          // مدة الإقامة

  LocationHistory({
    required this.id,
    required this.patientId,
    required this.placeName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.arrivedAt,
    this.departedAt,
    this.duration,
  });

  factory LocationHistory.fromJson(Map<String, dynamic> json) => LocationHistory(
    id: json['id'],
    patientId: json['patient_id'],
    placeName: json['place_name'],
    address: json['address'],
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    arrivedAt: DateTime.parse(json['arrived_at']),
    departedAt: json['departed_at'] != null ? DateTime.parse(json['departed_at']) : null,
    duration: json['duration_minutes'] != null 
        ? Duration(minutes: json['duration_minutes']) 
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'place_name': placeName,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'arrived_at': arrivedAt.toIso8601String(),
    'departed_at': departedAt?.toIso8601String(),
    'duration_minutes': duration?.inMinutes,
  };
}
```

#### 1.2 إنشاء Repository:

```dart
// lib/core/repositories/tracking_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class TrackingRepository {
  final SupabaseClient _supabase;

  TrackingRepository(this._supabase);

  // ========== Safe Zones ==========

  /// جلب جميع المناطق الآمنة لمريض معين
  Future<List<SafeZone>> getSafeZones(String patientId) async {
    try {
      final response = await _supabase
          .from('safe_zones')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => SafeZone.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch safe zones: $e');
    }
  }

  /// إضافة منطقة آمنة جديدة
  Future<SafeZone> createSafeZone(SafeZone zone) async {
    try {
      final response = await _supabase
          .from('safe_zones')
          .insert(zone.toJson())
          .select()
          .single();

      return SafeZone.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create safe zone: $e');
    }
  }

  /// تحديث منطقة آمنة
  Future<SafeZone> updateSafeZone(SafeZone zone) async {
    try {
      final response = await _supabase
          .from('safe_zones')
          .update({
            'name': zone.name,
            'address': zone.address,
            'latitude': zone.lat,
            'longitude': zone.lng,
            'radius_meters': zone.radiusMeters,
            'is_active': zone.isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', zone.id)
          .select()
          .single();

      return SafeZone.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update safe zone: $e');
    }
  }

  /// حذف منطقة آمنة
  Future<void> deleteSafeZone(String zoneId) async {
    try {
      await _supabase
          .from('safe_zones')
          .delete()
          .eq('id', zoneId);
    } catch (e) {
      throw Exception('Failed to delete safe zone: $e');
    }
  }

  // ========== Location Updates ==========

  /// إرسال موقع حالي للـ Database
  Future<void> updateLocation({
    required String patientId,
    required double latitude,
    required double longitude,
    String? address,
    double? accuracy,
  }) async {
    try {
      await _supabase.from('location_updates').insert({
        'patient_id': patientId,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'accuracy': accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  /// جلب آخر موقع معروف للمريض
  Future<PatientLocation?> getLastLocation(String patientId) async {
    try {
      final response = await _supabase
          .from('location_updates')
          .select()
          .eq('patient_id', patientId)
          .order('timestamp', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;
      return PatientLocation.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to fetch last location: $e');
    }
  }

  /// جلب سجل الحركة
  Future<List<LocationHistory>> getLocationHistory(
    String patientId, {
    int days = 7,
  }) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final response = await _supabase
          .from('location_history')
          .select()
          .eq('patient_id', patientId)
          .gte('arrived_at', since.toIso8601String())
          .order('arrived_at', ascending: false);

      return (response as List)
          .map((e) => LocationHistory.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch location history: $e');
    }
  }

  // ========== Real-time Streams ==========

  /// الاستماع للتحديثات الفورية (WebSocket)
  Stream<PatientLocation> watchLocationUpdates(String patientId) {
    return _supabase
        .from('location_updates')
        .on(RealtimeListenTypes.postgresChanges,
            event: RealtimeListenTypes.all,
            schema: 'public',
            table: 'location_updates',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'patient_id',
              value: patientId,
            ))
        .asyncMap((event) async {
          final data = event.payload['new'] as Map<String, dynamic>;
          return PatientLocation.fromJson(data);
        });
  }

  /// الاستماع لتحديثات Safe Zones
  Stream<SafeZone> watchSafeZones(String patientId) {
    return _supabase
        .from('safe_zones')
        .on(RealtimeListenTypes.postgresChanges,
            event: RealtimeListenTypes.all,
            schema: 'public',
            table: 'safe_zones',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'patient_id',
              value: patientId,
            ))
        .asyncMap((event) async {
          final data = event.payload['new'] as Map<String, dynamic>;
          return SafeZone.fromJson(data);
        });
  }
}
```

---

### **المرحلة 2: إنشاء BLoC/Cubit للتتبع**

```dart
// lib/screens/patient/live_tracking/cubit/patient_tracking_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

enum TrackingStatus { initial, loading, loaded, error }

class PatientTrackingState {
  final TrackingStatus status;
  final Position? currentPosition;
  final String? address;
  final DateTime? lastUpdated;
  final List<SafeZone> safeZones;
  final bool isInsideSafeZone;
  final String? errorMessage;

  PatientTrackingState({
    required this.status,
    this.currentPosition,
    this.address,
    this.lastUpdated,
    required this.safeZones,
    required this.isInsideSafeZone,
    this.errorMessage,
  });

  PatientTrackingState copyWith({
    TrackingStatus? status,
    Position? currentPosition,
    String? address,
    DateTime? lastUpdated,
    List<SafeZone>? safeZones,
    bool? isInsideSafeZone,
    String? errorMessage,
  }) => PatientTrackingState(
    status: status ?? this.status,
    currentPosition: currentPosition ?? this.currentPosition,
    address: address ?? this.address,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    safeZones: safeZones ?? this.safeZones,
    isInsideSafeZone: isInsideSafeZone ?? this.isInsideSafeZone,
    errorMessage: errorMessage,
  );
}

class PatientTrackingCubit extends Cubit<PatientTrackingState> {
  final TrackingRepository _trackingRepository;
  final String _patientId;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _safeZonesSubscription;
  Timer? _locationUpdateTimer;

  PatientTrackingCubit(
    this._trackingRepository,
    this._patientId,
  ) : super(PatientTrackingState(
    status: TrackingStatus.initial,
    safeZones: [],
    isInsideSafeZone: true,
  ));

  /// بدء المراقبة
  Future<void> initializeTracking() async {
    emit(state.copyWith(status: TrackingStatus.loading));
    try {
      // 1. جلب Safe Zones
      final zones = await _trackingRepository.getSafeZones(_patientId);
      emit(state.copyWith(safeZones: zones));

      // 2. جلب الموقع الأول
      await _updateLocation();

      // 3. بدء المراقبة الفورية
      _startRealTimeUpdates();

      emit(state.copyWith(status: TrackingStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
        status: TrackingStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// تحديث الموقع يدويًا
  Future<void> refreshLocation() async {
    await _updateLocation();
  }

  /// تحديث الموقع الداخلي
  Future<void> _updateLocation() async {
    try {
      // طلب الصلاحيات
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
        return;
      }

      // جلب الموقع
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // عكس الجيو-كود (اختياري)
      String? addr;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          addr = [
            if (p.street != null && p.street!.isNotEmpty) p.street,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality,
          ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
        }
      } catch (_) {}

      // إرسال للـ Database
      await _trackingRepository.updateLocation(
        patientId: _patientId,
        latitude: position.latitude,
        longitude: position.longitude,
        address: addr,
        accuracy: position.accuracy,
      );

      // حساب الأمان
      final isInside = _isInsideSafeZone(position.latitude, position.longitude);

      emit(state.copyWith(
        currentPosition: position,
        address: addr,
        lastUpdated: DateTime.now(),
        isInsideSafeZone: isInside,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to update location: $e',
      ));
    }
  }

  /// بدء المراقبة الفورية
  void _startRealTimeUpdates() {
    // 1. الاستماع لتحديثات Safe Zones من Database
    _safeZonesSubscription?.cancel();
    _safeZonesSubscription = _trackingRepository
        .watchSafeZones(_patientId)
        .listen((zone) {
      // تحديث Safe Zones
      final updatedZones = state.safeZones.map((z) {
        return z.id == zone.id ? zone : z;
      }).toList();
      emit(state.copyWith(safeZones: updatedZones));
    });

    // 2. تحديث الموقع كل 30 ثانية (يمكن تقليل الفترة)
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async => await _updateLocation(),
    );
  }

  /// حساب ما إذا كان المريض داخل منطقة آمنة
  bool _isInsideSafeZone(double lat, double lng) {
    for (final zone in state.safeZones) {
      if (!zone.isActive) continue;
      final distance = _haversineDistance(lat, lng, zone.lat, zone.lng);
      if (distance <= zone.radiusMeters) return true;
    }
    return false;
  }

  /// حساب المسافة بين نقطتين (Haversine)
  double _haversineDistance(
    double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0; // نصف قطر الأرض بالمتر
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double d) => d * pi / 180.0;

  /// إضافة منطقة آمنة جديدة
  Future<void> addSafeZone(SafeZone zone) async {
    try {
      final newZone = await _trackingRepository.createSafeZone(zone);
      emit(state.copyWith(
        safeZones: [...state.safeZones, newZone],
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to add safe zone: $e'));
    }
  }

  /// تحديث منطقة آمنة
  Future<void> updateSafeZone(SafeZone zone) async {
    try {
      final updated = await _trackingRepository.updateSafeZone(zone);
      final updatedZones = state.safeZones.map((z) {
        return z.id == updated.id ? updated : z;
      }).toList();
      emit(state.copyWith(safeZones: updatedZones));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update safe zone: $e'));
    }
  }

  /// حذف منطقة آمنة
  Future<void> deleteSafeZone(String zoneId) async {
    try {
      await _trackingRepository.deleteSafeZone(zoneId);
      final updatedZones = state.safeZones.where((z) => z.id != zoneId).toList();
      emit(state.copyWith(safeZones: updatedZones));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to delete safe zone: $e'));
    }
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _safeZonesSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    return super.close();
  }
}
```

---

### **المرحلة 3: قاعدة البيانات (Supabase)**

```sql
-- 1. جدول المناطق الآمنة
CREATE TABLE IF NOT EXISTS safe_zones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES auth.users(id),
  name TEXT NOT NULL,
  address TEXT,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  radius_meters DOUBLE PRECISION NOT NULL DEFAULT 200,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT unique_patient_zone UNIQUE(patient_id, name)
);

-- 2. جدول تحديثات الموقع
CREATE TABLE IF NOT EXISTS location_updates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES auth.users(id),
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  address TEXT,
  accuracy DOUBLE PRECISION,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. جدول السجل (يتم ملؤه بـ Trigger أو Backend Logic)
CREATE TABLE IF NOT EXISTS location_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES auth.users(id),
  place_name TEXT,
  address TEXT,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  arrived_at TIMESTAMP WITH TIME ZONE NOT NULL,
  departed_at TIMESTAMP WITH TIME ZONE,
  duration_minutes INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. الفهارس
CREATE INDEX idx_safe_zones_patient ON safe_zones(patient_id);
CREATE INDEX idx_location_updates_patient ON location_updates(patient_id, timestamp DESC);
CREATE INDEX idx_location_history_patient ON location_history(patient_id, arrived_at DESC);

-- 5. تفعيل Realtime (في Supabase)
ALTER TABLE safe_zones REPLICA IDENTITY FULL;
ALTER TABLE location_updates REPLICA IDENTITY FULL;
```

---

## 📝 الخلاصة

### **الحالة الحالية (Static):**
- ✗ بيانات مكتوبة بالكود
- ✗ لا توجد تحديثات فورية
- ✗ التعديلات تُفقد عند إغلاق التطبيق
- ✗ لا يوجد اتصال Backend

### **الحالة المستهدفة (Dynamic):**
- ✅ بيانات من Database
- ✅ تحديثات فورية عبر WebSocket
- ✅ حفظ دائم للتعديلات
- ✅ اتصال Backend آمن
- ✅ تزامن بين جميع الأجهزة (Doctor, Family, Patient)

### **الخطوات المقبلة:**
1. إنشاء Models و Repository
2. إعداد قاعدة البيانات (Supabase)
3. بناء BLoC/Cubit
4. تحديث الشاشات لاستخدام BLoC
5. اختبار المراقبة الفورية

---

**تم إنشاء هذا التحليل في:** 22 نوفمبر 2025
