# 🎯 دليل التحول من Static إلى Dynamic - عملي وتفصيلي

## 📊 رسم توضيحي للفرق

### الحالة الحالية (Static):
```
┌─────────────────────────────┐
│   Mobile App (Flutter)      │
│                             │
│  LiveTrackingScreen         │
│  ├─ _safeZones = const [   │
│  │    SafeZone(            │
│  │      name: 'Home',      │ ← مكتوب بالكود
│  │      lat: 31.034350,    │
│  │      lng: 30.471819,    │
│  │      radius: 20,        │
│  │    )                     │
│  │  ]                       │
│  │                          │
│  ├─ _position = null        │ ← جلب مرة واحدة
│  └─ _lastUpdated = null     │
│                             │
│  عند الإغلاق → تُفقد البيانات ❌
└─────────────────────────────┘
```

### الحالة المستهدفة (Dynamic):
```
┌──────────────────────────────────────────────────────────────┐
│                   Mobile App (Flutter)                        │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  PatientTrackingCubit                                   │ │
│  │  ├─ initializeTracking()  ─────┐                       │ │
│  │  ├─ refreshLocation()          │                       │ │
│  │  ├─ addSafeZone()              │                       │ │
│  │  ├─ updateSafeZone()      ────────────────────────┐   │ │
│  │  └─ deleteSafeZone()           │                  │   │ │
│  └─────────────────────────────────────────────────┬────────┘ │
│        ↓                                            │          │
│  LiveTrackingScreen                      TrackingRepository  │
│  (UI يعتمد على BLoC)                          │              │
└──────────────────────────────────────────────────┼──────────────┘
                                                    │
                ┌───────────────────────────────────┘
                ↓
        ┌──────────────────────────┐
        │   Backend (Node.js/Dart) │
        │                          │
        │  ✓ Authentication        │
        │  ✓ Validation            │
        │  ✓ Business Logic        │
        │  ✓ Real-time (WebSocket) │
        └──────────────┬───────────┘
                       ↓
        ┌──────────────────────────┐
        │  Database (Supabase)     │
        │                          │
        │  safe_zones              │ ← محفوظة بـ Database
        │  location_updates        │ ← تاريخ كامل
        │  location_history        │ ← مراقبة فورية
        │  users                   │
        └──────────────────────────┘
```

---

## 🔄 دورة الحياة للتحديث الديناميكي

### 1️⃣ **المرحلة: تحميل البيانات الأولية**

```
Patient تفتح الشاشة
         ↓
[BLoC] initializeTracking()
         ├─ 1. طلب Safe Zones من Database
         │      ↓
         │   [API] GET /safe-zones?patient_id=xxx
         │      ↓
         │   [Database] SELECT * FROM safe_zones WHERE patient_id = xxx
         │      ↓
         │   البيانات تُعود مباشرة
         │
         ├─ 2. جلب الموقع الحالي
         │      ↓
         │   [Geolocator] getCurrentPosition()
         │      ↓
         │   تحديث في Database
         │
         └─ 3. بدء المراقبة الفورية
                ↓
             [WebSocket] معدي الاستماع
```

### 2️⃣ **المرحلة: المراقبة المستمرة**

```
كل 30 ثانية:
         ↓
[Timer] _locationUpdateTimer tick()
         ├─ 1. جلب الموقع الحالي
         │      ↓
         │   [Geolocator] getCurrentPosition()
         │
         ├─ 2. إرسال للـ Database
         │      ↓
         │   [API] POST /locations
         │      {
         │        "patient_id": "xxx",
         │        "latitude": 31.041,
         │        "longitude": 30.465,
         │        "timestamp": "2024-11-22T14:30:00Z"
         │      }
         │      ↓
         │   [Database] INSERT INTO location_updates
         │
         └─ 3. تحديث الـ UI
                ↓
             emit(state.copyWith(
               currentPosition: position,
               lastUpdated: now
             ))
```

### 3️⃣ **المرحلة: تحديث Safe Zones**

```
Doctor يضيف Safe Zone جديدة
         ↓
[Doctor App] _openAddSafeZoneSheet()
         ├─ إدخال: Name, Lat, Lng, Radius
         │
         └─ onAdd() callback
              ↓
         [API] POST /safe-zones
              {
                "name": "Park",
                "patient_id": "xxx",
                "latitude": 37.3333,
                "longitude": -122.0293,
                "radius_meters": 150
              }
              ↓
         [Database] INSERT INTO safe_zones
              ↓
         **Realtime Notification**
              ├─ Patient تستقبل تحديث
              ├─ Family تستقبل تحديث
              └─ تحديث الـ UI تلقائيًا
```

---

## 🛠️ مثال عملي: تحويل Patient Tracking

### قبل (Static):

```dart
class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  Position? _pos;
  final List<_SafeZone> _safeZones = const [
    _SafeZone(
      name: 'Home',
      lat: 31.034350,
      lng: 30.471819,
      radiusMeters: 20,
      isActive: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // مرة واحدة فقط
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Text('Status: ${_insideAnyZone ? "Safe" : "Outside"}'),
          Text('Position: ${_pos?.latitude}, ${_pos?.longitude}'),
          ElevatedButton(
            onPressed: _getCurrentLocation, // تحديث يدويًا فقط
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
```

### بعد (Dynamic):

```dart
class PatientTrackingScreen extends StatefulWidget {
  final String patientId;
  
  const PatientTrackingScreen({
    required this.patientId,
    Key? key,
  }) : super(key: key);

  @override
  State<PatientTrackingScreen> createState() => _PatientTrackingScreenState();
}

class _PatientTrackingScreenState extends State<PatientTrackingScreen> {
  late PatientTrackingCubit _cubit;

  @override
  void initState() {
    super.initState();
    
    // 1. إنشاء Cubit مع Dependency Injection
    _cubit = PatientTrackingCubit(
      TrackingRepository(Supabase.instance.client),
      widget.patientId,
    );

    // 2. بدء المراقبة الفورية
    _cubit.initializeTracking();
  }

  @override
  void dispose() {
    _cubit.close(); // إيقاف Streams
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<PatientTrackingCubit, PatientTrackingState>(
        bloc: _cubit,
        builder: (context, state) {
          // 1. حالة التحميل
          if (state.status == TrackingStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. حالة الخطأ
          if (state.status == TrackingStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.errorMessage}'),
                  ElevatedButton(
                    onPressed: _cubit.initializeTracking,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // 3. الحالة الطبيعية
          return Column(
            children: [
              // Status Badge (يتحدث تلقائيًا)
              Container(
                padding: const EdgeInsets.all(16),
                color: state.isInsideSafeZone ? Colors.green[100] : Colors.red[100],
                child: Row(
                  children: [
                    Icon(
                      state.isInsideSafeZone
                          ? Icons.check_circle
                          : Icons.warning,
                      color: state.isInsideSafeZone ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.isInsideSafeZone ? '🟢 Safe Zone' : '🔴 Outside Zone',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (state.address != null)
                          Text(
                            'Address: ${state.address}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (state.lastUpdated != null)
                          Text(
                            'Updated: ${_timeAgo(state.lastUpdated)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Safe Zones List (يتحدث تلقائيًا عند تغيير)
              Expanded(
                child: ListView.builder(
                  itemCount: state.safeZones.length,
                  itemBuilder: (context, index) {
                    final zone = state.safeZones[index];
                    return Card(
                      child: ListTile(
                        title: Text(zone.name),
                        subtitle: Text(zone.address),
                        trailing: Switch(
                          value: zone.isActive,
                          onChanged: (value) {
                            // تحديث في Database
                            _cubit.updateSafeZone(
                              zone.copyWith(isActive: value),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _cubit.refreshLocation,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // فتح dialog لإضافة منطقة آمنة
                        _showAddSafeZoneDialog(context);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Zone'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '—';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    return '${diff.inHours} hours ago';
  }

  void _showAddSafeZoneDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    double radius = 200;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Safe Zone'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name (e.g., Park)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: latCtrl,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lngCtrl,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Slider(
                min: 50,
                max: 500,
                divisions: 9,
                value: radius,
                label: '${radius.toInt()}m',
                onChanged: (v) => setState(() => radius = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final lat = double.tryParse(latCtrl.text);
              final lng = double.tryParse(lngCtrl.text);
              
              if (lat == null || lng == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid coordinates')),
                );
                return;
              }

              final zone = SafeZone(
                id: '', // سيتم تعيينه من Database
                patientId: widget.patientId,
                name: nameCtrl.text,
                address: addrCtrl.text,
                lat: lat,
                lng: lng,
                radiusMeters: radius,
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              // إضافة إلى Database (تلقائيًا يتم التحديث)
              _cubit.addSafeZone(zone);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
```

---

## 📡 مثال: Real-time Updates (WebSocket)

### كيفية عمل المراقبة الفورية:

```dart
// في Repository
Stream<SafeZone> watchSafeZones(String patientId) {
  return _supabase
      .from('safe_zones')
      .on(RealtimeListenTypes.postgresChanges,
          event: RealtimeListenTypes.all,
          table: 'safe_zones',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: patientId,
          ))
      .map((event) {
        // INSERT: event.eventType == 'INSERT'
        // UPDATE: event.eventType == 'UPDATE'
        // DELETE: event.eventType == 'DELETE'
        return SafeZone.fromJson(event.payload['new']);
      });
}

// في Cubit
void _startRealTimeUpdates() {
  // الاستماع للتحديثات والتفاعل معها تلقائيًا
  _safeZonesSubscription = _trackingRepository
      .watchSafeZones(_patientId)
      .listen((zone) {
        // تحديث محلي
        final updatedZones = state.safeZones.map((z) {
          return z.id == zone.id ? zone : z;
        }).toList();
        
        emit(state.copyWith(safeZones: updatedZones));
        
        // إذا تغيرت منطقة ما، أعد حساب الأمان
        final isInside = _isInsideSafeZone(
          state.currentPosition!.latitude,
          state.currentPosition!.longitude,
        );
        
        emit(state.copyWith(isInsideSafeZone: isInside));
      });
}
```

### السيناريو:

```
الدكتور يضيف منطقة آمنة جديدة "Park"
                ↓
[Doctor App] تُرسل POST /safe-zones
                ↓
[Backend] يحفظ في Database
                ↓
[Database Trigger] sends broadcast notification
                ↓
┌──────────────────┬────────────────────┬──────────────────┐
↓                  ↓                     ↓                  ↓
[Patient App]   [Family App]       [Another Patient]  [Another Doctor]
Real-time      Real-time          Real-time          Real-time
تحديث           تحديث             تحديث             تحديث
```

---

## 📋 خطوات التطبيق العملية

### ✅ الخطوة 1: الإعداد الأساسي

```bash
# 1. إضافة المكتبات المطلوبة
flutter pub add flutter_bloc bloc supabase_flutter

# 2. الحصول على API Key من Supabase
# اذهب إلى https://app.supabase.io
# انسخ المفاتيح في البيئة
```

### ✅ الخطوة 2: إنشاء Models

```dart
// lib/core/models/tracking_models.dart
// (كما شرح أعلاه في الملف الرئيسي)
```

### ✅ الخطوة 3: إنشاء Repository

```dart
// lib/core/repositories/tracking_repository.dart
// (كما شرح أعلاه)
```

### ✅ الخطوة 4: إنشاء BLoC/Cubit

```dart
// lib/screens/patient/live_tracking/cubit/patient_tracking_cubit.dart
// (كما شرح أعلاه)
```

### ✅ الخطوة 5: تحديث الشاشة

```dart
// lib/screens/patient/live_tracking_screen.dart
// دمج BLocBuilder و استخدام Cubit
```

### ✅ الخطوة 6: إعداد قاعدة البيانات

```sql
-- تشغيل الـ SQL scripts في Supabase Console
-- (كما شرح أعلاه)
```

---

## 🧪 اختبار:

### السيناريو 1: تحديث تلقائي للموقع
```
1. افتح التطبيق
2. اتوقع: الموقع يتحدث تلقائيًا كل 30 ثانية
3. تحقق من Database: location_updates يجب أن يكون عنده سجل جديد كل 30 ثانية
```

### السيناريو 2: إضافة منطقة آمنة من Doctor
```
1. Doctor يفتح Safe Zones Editor
2. يضيف منطقة "Park"
3. في نفس اللحظة: Patient والـ Family يشوفوا المنطقة الجديدة
4. تحقق: Database عنده safe_zones جديد
```

### السيناريو 3: مغادرة Safe Zone
```
1. Patient في "Home"
2. يتحرك خارج المنطقة
3. Status يتغير من 🟢 Safe إلى 🔴 Outside
4. Database location_history يسجل: departed_at
```

---

## ⚠️ النقاط المهمة

### 1. الصلاحيات (Permissions)
```dart
// iCloud (iOS)
POST_NOTIFICATIONS
LOCATION

// Android
android.permission.ACCESS_FINE_LOCATION
android.permission.ACCESS_COARSE_LOCATION
android.permission.POST_NOTIFICATIONS
```

### 2. كفاءة البطارية
```dart
// استخدم LocationAccuracy.low للحفظ على البطارية
final position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.low, // ← lower accuracy = less power
);

// أو استخدم Geolocator.getPositionStream لتحديث مستمر
Geolocator.getPositionStream(
  locationSettings: LocationSettings(
    accuracy: LocationAccuracy.low,
    distanceFilter: 100, // تحديث فقط عند حركة 100 متر
  ),
).listen((position) {
  // موقع جديد
});
```

### 3. خصوصية المستخدم
```dart
// التأكد من طلب الموافقة قبل تتبع الموقع
final permission = await Geolocator.requestPermission();
if (permission == LocationPermission.deniedForever) {
  // المستخدم رفض بشكل نهائي → افتح الإعدادات
  await Geolocator.openAppSettings();
}
```

### 4. الأمان (Security)
```dart
// استخدم Row-level Security (RLS) في Supabase
CREATE POLICY "Users can only see their own data" ON safe_zones
  FOR SELECT USING (auth.uid() = patient_id);

CREATE POLICY "Only the patient or doctor can update zones" ON safe_zones
  FOR UPDATE USING (
    auth.uid() = patient_id OR auth.uid() IN (
      SELECT doctor_id FROM patient_doctors WHERE patient_id = safe_zones.patient_id
    )
  );
```

---

## 🎬 الخلاصة

| الميزة | Static (الآن) | Dynamic (المستقبل) |
|------|-------------|-------------------|
| **مصدر البيانات** | Hard-coded | Database |
| **التحديث** | يدويًا | تلقائيًا كل 30 ثانية |
| **الحفظ** | لا | نعم (Permanent) |
| **التزامن** | لا | نعم (Realtime) |
| **الأمان** | ضعيف | قوي (RLS) |
| **التوسع** | محدود | غير محدود |

---

**النسخة:** 1.0  
**التاريخ:** 22 نوفمبر 2025  
**الحالة:** جاهز للتطبيق 🚀
