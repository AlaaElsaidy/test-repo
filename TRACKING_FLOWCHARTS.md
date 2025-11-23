# 🎨 رسوم توضيحية وفلوتشارتس - نظام التتبع

## 📊 1. مخطط البيانات الكامل

```
┌─────────────────────────────────────────────────────────────────┐
│                        Mobile App (Flutter)                      │
│                                                                   │
│  ┌──────────────────┬──────────────────┬──────────────────┐     │
│  │  Patient Screen  │  Family Screen   │  Doctor Screen   │     │
│  │                  │  (3 Tabs)        │  (Multi-patient) │     │
│  │  - Location      │  - Live Track    │  - Dropdown      │     │
│  │  - Safe Status   │  - Safe Zones    │  - Tracking      │     │
│  │  - Emergency Btn │  - History       │  - Safe Zones    │     │
│  │                  │                  │  - History       │     │
│  └─────────┬────────┴─────────┬────────┴────────┬─────────┘     │
│            │                  │                 │                │
│            └──────────────────┼─────────────────┘                │
│                               │                                  │
│            ┌──────────────────▼──────────────────┐               │
│            │   Presentation Layer (Widgets)     │               │
│            │   - BlocBuilder                    │               │
│            │   - BlocListener                   │               │
│            └──────────────────┬──────────────────┘               │
│                               │                                  │
│            ┌──────────────────▼──────────────────┐               │
│            │   BLoC/Cubit Layer                 │               │
│            │   - PatientTrackingCubit           │               │
│            │   - FamilyTrackingCubit            │               │
│            │   - DoctorTrackingCubit            │               │
│            └──────────────────┬──────────────────┘               │
│                               │                                  │
│            ┌──────────────────▼──────────────────┐               │
│            │   Repository Layer                 │               │
│            │   - TrackingRepository             │               │
│            │   - Gets/Creates/Updates/Deletes   │               │
│            └──────────────────┬──────────────────┘               │
│                               │                                  │
└───────────────────────────────┼──────────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
           ┌────────▼────────┐    ┌────────▼────────┐
           │   API Calls     │    │  WebSocket      │
           │   (REST)        │    │  (Real-time)    │
           └────────┬────────┘    └────────┬────────┘
                    │                       │
        ┌───────────┴───────────────────────┴──────────────┐
        │                                                   │
    ┌───▼─────────────────────────────────────────────┐    │
    │        Backend Server (Node.js/Dart)           │    │
    │                                                 │    │
    │  - Authentication                              │    │
    │  - API Routes                                  │    │
    │  - Validation                                  │    │
    │  - Broadcast Events                            │    │
    │  - Logging                                      │    │
    └───┬─────────────────────────────────────────────┘    │
        │                                                   │
    ┌───▼─────────────────────────────────────────────┐    │
    │        Database (Supabase PostgreSQL)          │    │
    │                                                 │    │
    │  ┌─────────────────────────────────────────┐  │    │
    │  │ safe_zones                              │  │    │
    │  │ ├─ id, patient_id, name, lat, lng      │  │    │
    │  │ ├─ address, radius_meters, is_active   │  │    │
    │  │ └─ created_at, updated_at              │  │    │
    │  └─────────────────────────────────────────┘  │    │
    │                                                 │    │
    │  ┌─────────────────────────────────────────┐  │    │
    │  │ location_updates (Real-time ← GPS)     │  │    │
    │  │ ├─ id, patient_id, lat, lng            │  │    │
    │  │ ├─ address, accuracy, timestamp        │  │    │
    │  │ └─ 300+ entries/day/patient            │  │    │
    │  └─────────────────────────────────────────┘  │    │
    │                                                 │    │
    │  ┌─────────────────────────────────────────┐  │    │
    │  │ location_history (Auto-tracked)        │  │    │
    │  │ ├─ id, patient_id, place_name          │  │    │
    │  │ ├─ address, arrived_at, departed_at    │  │    │
    │  │ └─ duration_minutes                    │  │    │
    │  └─────────────────────────────────────────┘  │    │
    │                                                 │    │
    │  ┌─────────────────────────────────────────┐  │    │
    │  │ users, emergency_contacts, ...         │  │    │
    │  └─────────────────────────────────────────┘  │    │
    └───┬─────────────────────────────────────────────┘    │
        │                                                   │
        └─────────────────────────────────────────────────┘
```

---

## 🔄 2. دورة حياة التطبيق

### **عند فتح الشاشة (Initialization):**

```
Patient Opens App
        │
        ▼
PatientTrackingScreen created
        │
        ▼
initState() called
        │
        ├─► _cubit = PatientTrackingCubit(...)
        │
        └─► _cubit.initializeTracking()
                    │
                    ├─► Step 1: Load Safe Zones
                    │           │
                    │           ▼
                    │    repository.getSafeZones(patientId)
                    │           │
                    │           ▼
                    │    API GET /safe-zones?patient_id=xxx
                    │           │
                    │           ▼
                    │    Database SELECT * FROM safe_zones WHERE patient_id=xxx
                    │           │
                    │           ▼
                    │    return List<SafeZone>
                    │           │
                    ├─► Step 2: Get Current Location
                    │           │
                    │           ▼
                    │    Geolocator.getCurrentPosition()
                    │           │
                    │           ▼
                    │    GPS response (lat, lng, accuracy)
                    │           │
                    │           ▼
                    │    Reverse Geocode to get address
                    │           │
                    │           ▼
                    │    Send to Database via API
                    │           │
                    │           ▼
                    │    INSERT location_updates
                    │           │
                    ├─► Step 3: Calculate Safety
                    │           │
                    │           ▼
                    │    Check if inside any active zone
                    │           │
                    │           ▼
                    │    emit(state.copyWith(
                    │      status: loaded,
                    │      safeZones: [...],
                    │      isInsideSafeZone: true/false
                    │    ))
                    │           │
                    ├─► Step 4: Start Real-time Updates
                    │           │
                    │           ▼
                    │    _startLocationUpdateTimer()
                    │    (every 30 seconds)
                    │           │
                    └─► Step 5: Listen to WebSocket
                                │
                                ▼
                        watchSafeZones(patientId)
                                │
                                ▼
                        Waiting for changes...
                                │
                    (Will trigger when safe zones change)
```

### **أثناء المراقبة المستمرة (Monitoring):**

```
Timer ticks every 30 seconds
        │
        ▼
_updateLocation() called
        │
        ├─► Geolocator.getCurrentPosition()
        │
        ├─► Check if location changed significantly
        │
        ├─► Reverse geocode
        │
        ├─► Send to API: POST /locations
        │       {
        │         "patient_id": "xxx",
        │         "latitude": 31.041243,
        │         "longitude": 30.465516,
        │         "address": "Home",
        │         "accuracy": 5.2,
        │         "timestamp": "2024-11-22T14:30:00Z"
        │       }
        │
        ├─► Database: INSERT location_updates
        │
        ├─► Check if inside any zone
        │
        └─► emit(state.copyWith(
              currentPosition: position,
              address: addr,
              isInsideSafeZone: calculated,
              lastUpdated: now
            ))
            │
            ▼
        BlocBuilder rebuilds UI
            │
            ├─► Status badge updates (Safe/Outside)
            ├─► Address updates
            ├─► Last updated timestamp updates
            └─► Location history updated
```

---

## 🔐 3. تحديث Safe Zones (Real-time Sync)

```
Doctor App                        Backend                 Patient App
      │                              │                          │
      │ 1. User clicks "Add Zone"   │                          │
      │                              │                          │
      ├─ 2. Opens dialog             │                          │
      │    (inputs: Park, lat, lng)  │                          │
      │                              │                          │
      ├─ 3. Calls cubit.addSafeZone()│                          │
      │          │                   │                          │
      │          ▼                   │                          │
      │    POST /safe-zones          │                          │
      │    ─────────────────────────►│ 4. Validates             │
      │                              │    - Auth check          │
      │                              │    - Doctor owns patient │
      │                              │    - Coordinates valid   │
      │                              │                          │
      │                              ▼                          │
      │                          INSERT into safe_zones        │
      │                              │                          │
      │                              ▼                          │
      │                          Database Trigger              │
      │                          (LISTEN safe_zones)           │
      │                              │                          │
      │        ┌─────────────────────┼─────────────────────┐   │
      │        │                     │                     │   │
      │        ▼                     ▼                     ▼   │
      │ 5a. WebSocket broadcast 5b. WebSocket broadcast     │
      │     "safe_zone_added"       "safe_zone_added"       │
      │        │                     │                     │
      ◄────────┘                     │                     │
      │ 6a. Receive event                                  │
      │     (in _safeZonesSubscription)                    │
      │                              │                     ◄────
      │                              │ 6b. Receive event       │
      │                              │     (in _safeZonesSubscription)
      │                              │
      ▼                              │                     ▼
7a. Update local state               │                 7b. Update local state
    safeZones.add(newZone)           │                     safeZones.add(newZone)
    │                                │                     │
    ▼                                │                     ▼
8a. emit(state.copyWith(...))        │                 8b. emit(state.copyWith(...))
    │                                │                     │
    ▼                                │                     ▼
9a. BlocBuilder rebuilds             │                 9b. BlocBuilder rebuilds
    Safe Zones list shows new zone   │                     Safe Zones list shows new zone
    │                                │                     │
    ▼                                │                     ▼
10a. User sees "Park 150m"           │                 10b. Patient sees "Park 150m"
     ✅ Zone added successfully      │                     ✅ New zone appears immediately
```

---

## 📍 4. حساب الأمان (Safety Calculation)

```
Current Position: (31.041243, 30.465516)

Safe Zones:
  1. Home:     (31.034350, 30.471819, radius: 200m)
  2. Park:     (37.3333, -122.0293, radius: 150m)
  3. Hospital: (37.3270, -122.0305, radius: 100m)

Algorithm: Haversine Distance

For each active zone:
  ├─ distance = haversine(currentPos, zonePos)
  │
  └─ if distance <= zone.radius
      └─► INSIDE ZONE ✅ (Green status)
  
  if all zones checked and outside:
      └─► OUTSIDE ZONES ❌ (Red status)

Example:
  Distance to Home = 820 meters
    └─ 820 > 200 (radius) → OUTSIDE HOME
  
  Distance to Park = 45 kilometers
    └─ 45,000 > 150 (radius) → OUTSIDE PARK
  
  Distance to Hospital = 44 kilometers
    └─ 44,000 > 100 (radius) → OUTSIDE HOSPITAL
  
  Result: Status = 🔴 OUTSIDE ZONE
```

---

## 📊 5. Flow للـ History Tracking

```
Patient Location Changed (detected by timer)
        │
        ▼
Check if in zone A
        │
        ├─ If was outside A, now inside A:
        │   ├─ Record arrival_at = now
        │   ├─ Create new history entry
        │   └─ Database: INSERT location_history (arrived_at filled)
        │
        ├─ If was inside A, now outside A:
        │   ├─ Find last history entry (place=A)
        │   ├─ Record departure_at = now
        │   ├─ Calculate duration = departure_at - arrival_at
        │   └─ Database: UPDATE location_history (add departed_at, duration)
        │
        └─ If stayed in A:
            └─ Do nothing (already recorded)

Example Timeline:

14:00 → Arrived at Home
        Database: INSERT location_history
        ├─ place_name: 'Home'
        ├─ address: '123 Oak Street'
        ├─ arrived_at: 14:00
        ├─ departed_at: NULL
        └─ duration_minutes: NULL

14:45 → Left Home
        Database: UPDATE location_history
        ├─ departed_at: 14:45
        ├─ duration_minutes: 45
        └─ This entry now complete ✅

14:50 → Arrived at Park
        Database: INSERT location_history (new entry)
        ├─ place_name: 'Park'
        ├─ address: 'Central Park'
        ├─ arrived_at: 14:50
        ├─ departed_at: NULL
        └─ duration_minutes: NULL
        
(continues...)

Result: History becomes:
[
  {place: 'Home', duration: 45 mins},
  {place: 'Park', duration: 30 mins},
  {place: 'Hospital', duration: 2 hours},
  ...
]
```

---

## 🔐 6. Security Flow (Authentication & Authorization)

```
┌─ Patient requests location_updates
│
├─► Token validation
│   ├─ Is token valid?
│   ├─ Is token not expired?
│   └─ Is user authenticated?
│
├─► Authorization check
│   ├─ Can patient access their own location? ✅
│   └─ Can patient access other patients? ❌ RLS blocks
│
├─► Database level (Row-Level Security)
│   ├─ SELECT * FROM location_updates
│   │   WHERE auth.uid() = patient_id OR
│   │         auth.uid() IN (SELECT doctor_id FROM patient_doctors WHERE ...)
│   │
│   └─ Only return rows where user has access ✅
│
└─► Response
    ├─ Safe: Own data only
    ├─ Doctor: All assigned patients' data
    └─ Family: Only assigned patient's data
```

---

## 📈 7. Performance & Optimization

```
Current Load (per patient):

Location Updates:
  ├─ Frequency: Every 30 seconds
  ├─ Size per update: ~300 bytes
  ├─ Requests/day: 2,880 (30-sec × 86400/30)
  └─ Data/day: ~864 KB

Safe Zone Changes:
  ├─ Frequency: Rarely (5-10 times/day)
  ├─ Size per update: ~500 bytes
  └─ Data/day: ~5 KB

History Queries:
  ├─ Frequency: App open (1-2 times/day)
  ├─ Size: ~10 KB (7 days history)
  └─ Data/day: ~20 KB

Total per patient/day: ~900 KB

Optimization strategies:
  ├─ Use LocationAccuracy.low (saves battery)
  ├─ Distance filter: 100m (skip small movements)
  ├─ Pagination for history (load older data on-demand)
  ├─ Database indexes on patient_id, timestamp
  └─ Cache safe zones locally (refresh every 10 mins)
```

---

## 🎯 8. Complete Feature Matrix

```
┌─────────────────┬──────────┬────────┬────────┐
│ Feature         │ Patient  │ Family │ Doctor │
├─────────────────┼──────────┼────────┼────────┤
│ See Own Loc.    │   ✅     │   -    │   -    │
│ See Patient Loc │   -      │   ✅   │   ✅   │
│ Safe Zone Check │   ✅     │   ✅   │   ✅   │
│ Add Safe Zone   │   ❌     │   ✅   │   ✅   │
│ Edit Safe Zone  │   ❌     │   ✅   │   ✅   │
│ Delete Safe Zone│   ❌     │   ✅   │   ✅   │
│ View History    │   ❌     │   ✅   │   ✅   │
│ Emergency Alert │   ✅     │   ❌   │   ❌   │
│ See Multiple Pat│   ❌     │   ❌   │   ✅   │
│ Real-time Sync  │   ✅     │   ✅   │   ✅   │
│ Offline Support │   ✅*    │   ✅*  │   ✅*  │
└─────────────────┴──────────┴────────┴────────┘

Legend:
  ✅ = Full support
  ❌ = Not available
  ✅* = Queued & synced when online
  - = Not applicable
```

---

**تم الإنشاء:** 22 نوفمبر 2025  
**الإصدار:** 2.0 - مع جميع الرسوم التوضيحية
