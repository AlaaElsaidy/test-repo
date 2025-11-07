# نظرة شاملة على جميع الشاشات - AlzCare 📱

## إجمالي الشاشات: 15 شاشة ✨

---

## 👤 واجهة المريض (5 شاشات)

### 1️⃣ Patient Dashboard
**الملف**: `lib/screens/patient/patient_dashboard.dart`

**المحتوى**:
- 👋 ترحيب شخصي
- 📊 إحصائيات سريعة (Activities: 12/15, Points: 890)
- 📈 تقدم الذاكرة (Face Recognition 85%, Photo Matching 72%, Music 90%)
- 📅 الموعد القادم
- ⏰ تذكيرات اليوم
- 🛡️ حالة الموقع

**الألوان**: Teal & Cyan gradient

---

### 2️⃣ Memory Activities
**الملف**: `lib/screens/patient/memory_activities_screen.dart`

**المحتوى**:
- 🎯 التقدم اليومي (4/7 Activities)
- 📋 قائمة الأنشطة المتاحة:
  - Face Recognition (Easy - 10 mins - 50 pts)
  - Photo Memory (Medium - 15 mins - 75 pts)
  - Music Memories (Easy - 20 mins - 60 pts)
  - Story Recall (Hard - 25 mins - 100 pts)
- ✅ علامات الأنشطة المكتملة
- 🏆 نظام النقاط

**التفاعل**: Tap على النشاط للبدء

---

### 3️⃣ Live Tracking
**الملف**: `lib/screens/patient/live_tracking_screen.dart`

**المحتوى**:
- 🗺️ خريطة توضيحية
- 📍 الموقع الحالي (123 Oak Street, Springfield)
- 🟢 حالة الأمان (Safe Zone)
- 🔄 زر التحديث
- ⏱️ آخر تحديث
- 🚨 زر تنبيه الطوارئ

**الميزات**:
- مؤشر دائري للمنطقة الآمنة
- تحديث الموقع في الوقت الفعلي
- إرسال تنبيه طوارئ

---

### 4️⃣ Chat with Doctor
**الملف**: `lib/screens/patient/chat_with_doctor_screen.dart`

**المحتوى**:
- 💬 محادثة ثنائية مع الطبيب
- 👤 صورة ملف الطبيب
- 🟢 حالة الاتصال (Online/Offline)
- ⌚ طوابع زمنية للرسائل
- 📎 إرفاق ملفات
- 😊 إيموجي
- 📞 مكالمة صوتية
- 📹 مكالمة مرئية

**التصميم**:
- رسائل الطبيب: Teal background
- رسائل المريض: White background

---

### 5️⃣ Patient Profile
**الملف**: `lib/screens/patient/patient_profile_screen.dart`

**المحتوى**:
- 👤 صورة الملف الشخصي
- 📋 معلومات المريض (Margaret Smith, 72 years)
- 🏥 المرحلة (Early Alzheimer's)
- 📞 معلومات الاتصال
- 🚨 جهة اتصال الطوارئ (Emily Smith - Daughter)
- ⚙️ الإعدادات:
  - Notifications
  - Privacy & Security
  - Edit Profile
- 🚪 Logout

---

## 👨‍⚕️ واجهة الطبيب (6 شاشات)

### 1️⃣ Doctor Dashboard
**الملف**: `lib/screens/doctor/doctor_dashboard.dart`

**المحتوى**:
- 👋 ترحيب (Dr. Sarah Johnson)
- 📊 إحصائيات:
  - Active Patients: 24
  - Appointments: 8
- 📅 مواعيد اليوم:
  - Margaret Smith - 10:00 AM
  - John Davis - 11:30 AM
  - Emily Wilson - 2:00 PM
- ⚠️ تنبيهات تحتاج انتباه:
  - Robert Brown: Missed 2 activities
  - Mary Taylor: Outside safe zone
- 🔔 أنشطة المرضى الأخيرة

**الميزات**:
- عرض سريع لحالة جميع المرضى
- تنبيهات فورية
- الوصول السريع للمواعيد

---

### 2️⃣ Advice & Resources
**الملف**: `lib/screens/doctor/doctor_advice_screen.dart`

**المحتوى**:
- 🔍 شريط البحث
- 🏷️ فئات:
  - All
  - Handling Situations
  - Support Groups
  - Caregiver Tips
- ⭐ مقال مميز
- 📚 مقالات شائعة:
  1. **Understanding Memory Loss Stages** (Handling Situations - 5 min)
  2. **Local Support Groups Near You** (Support Groups - 3 min)
  3. **Self-Care Tips for Caregivers** (Caregiver Tips - 7 min)
  4. **Managing Sundown Syndrome** (Handling Situations - 6 min)
  5. **Communication Strategies** (Caregiver Tips - 4 min)
  6. **Online Support Communities** (Support Groups - 3 min)

**التفاعل**: Tap على المقال للقراءة

---

### 3️⃣ Activities Management
**الملف**: `lib/screens/doctor/doctor_activities_screen.dart`

**المحتوى**:
- 👤 اختيار المريض
- 📊 إحصائيات:
  - Active Activities: 12
  - Completed Today: 8
- 📋 أنشطة اليوم:
  - Take Morning Medication (9:00 AM - ✅ Completed)
  - Memory Exercise (11:00 AM - ✅ Completed)
  - Lunch Reminder (12:30 PM - ⏳ Pending)
  - Afternoon Walk (3:00 PM - 📅 Scheduled)
  - Evening Medication (6:00 PM - 📅 Scheduled)
- 📑 قوالب الأنشطة:
  - Memory Games
  - Physical Activities
  - Social Engagement

**الميزات**:
- إضافة أنشطة جديدة
- تعديل الأنشطة الحالية
- استخدام القوالب الجاهزة

---

### 4️⃣ Live Tracking
**الملف**: `lib/screens/doctor/doctor_tracking_screen.dart`

**المحتوى**:
- 📋 قائمة منسدلة لاختيار المريض
- 🗺️ خريطة توضيحية
- 🟢 حالة الأمان
- 📍 معلومات الموقع:
  - Current Location
  - Last Updated
- 🧭 Get Directions
- 📜 History
- ⚙️ Edit Safe Zones

**Safe Zones Dialog**:
- Home (200m - Active)
- Park (150m - Active)
- Hospital (100m - Inactive)
- ➕ Add New Safe Zone

**الميزات**:
- متابعة عدة مرضى
- تحديث فوري
- إدارة المناطق الآمنة

---

### 5️⃣ Doctor Chat
**الملف**: `lib/screens/doctor/doctor_chat_screen.dart`

**المحتوى**:
- 📑 ثلاث تبويبات:
  - Patients
  - Families
  - Groups
- 💬 قائمة المحادثات:
  - Margaret Smith (2 unread)
  - Emily Smith (Family)
  - John Davis (1 unread)
  - Support Group - Caregivers
  - Mary Taylor
  - Robert Brown (Family)
- 🔍 بحث
- 🟢 حالة الاتصال

**الميزات**:
- محادثات منفصلة للمرضى والعائلات
- مجموعات دعم
- مكالمات صوتية/مرئية

---

### 6️⃣ Doctor Profile
**الملف**: `lib/screens/doctor/doctor_profile_screen.dart`

**المحتوى**:
- 👨‍⚕️ Dr. Sarah Johnson
- 🎓 Neurologist - Alzheimer's Specialist
- 📊 إحصائيات:
  - Active Patients: 24
  - Total Cases: 156
- 📞 معلومات الاتصال
- ⚙️ الإعدادات:
  - Notifications
  - Working Hours
  - Privacy & Security
  - Help & Support
- 🚪 Logout

---

## 👨‍👩‍👧 واجهة العائلة (4 شاشات)

### 1️⃣ Family Dashboard
**الملف**: `lib/screens/family/family_dashboard.dart`

**المحتوى**:
- 👋 Hello, Emily (Caring for Margaret Smith)
- 🟢 Status: Everything is going well
- 📊 Current Status:
  - 📍 Location: At Home
  - 🎯 Activities: 8/12 Completed
- ⚡ أزرار سريعة:
  - View Location
  - Chat
- 📅 جدول اليوم:
  - Morning Medication (9:00 AM - ✅)
  - Memory Exercise (11:00 AM - ✅)
  - Doctor Appointment (2:00 PM - ⏳)
- 💡 نصيحة اليوم
- 🚨 Emergency Contact (Dr. Johnson)

**الميزات**:
- نظرة شاملة لحالة المريض
- الوصول السريع للميزات
- نصائح يومية

---

### 2️⃣ Family Tracking (3 أوضاع)
**الملف**: `lib/screens/family/family_tracking_screen.dart`

#### 🔴 Live Tracking
- 🗺️ خريطة توضيحية
- 📍 الموقع الحالي
- 🟢 Safe Zone indicator
- 🔄 Refresh button
- 🧭 Get Directions to Patient

#### 🛡️ Safe Zones
- 🏠 Home (200m - Active - ✅ Inside)
- 🌳 Park (150m - Active)
- 🏥 Hospital (100m - Active)
- ⛪ Church (100m - Inactive)

#### 📜 History
- 🏠 Home (2 mins ago - Current location)
- 🌳 Park (2 hours ago - 45 minutes)
- 🏥 Hospital (Yesterday - 2 hours)
- 🛍️ Shopping Center (2 days ago - 1 hour)

**الميزات المميزة**:
- ثلاثة أوضاع في شاشة واحدة
- تبديل سهل بين الأوضاع
- معلومات تفصيلية لكل وضع

---

### 3️⃣ Family Chat
**الملف**: `lib/screens/family/family_chat_screen.dart`

**المحتوى**:
- 💬 محادثة مع المريض (Margaret)
- 🟢 Online status
- 📊 شريط معلومات سريع:
  - 📍 At Home
  - ✅ 8/12 Activities
  - ❤️ Feeling Good
- 📞 مكالمة صوتية
- 📹 مكالمة مرئية
- 📎 إرفاق ملفات
- 😊 إيموجي

**التصميم**:
- رسائل العائلة: Teal background
- رسائل المريض: White background
- شريط معلومات في الأعلى

---

### 4️⃣ Family Profile
**الملف**: `lib/screens/family/family_profile_screen.dart`

**المحتوى**:
- 👤 Emily Smith
- 👩‍👧 Daughter & Primary Caregiver
- 🔗 Caring for Margaret Smith
- 📋 معلومات المريض:
  - Margaret Smith, 72 years
  - Early Alzheimer's Stage
- 📞 معلومات الاتصال
- 🩺 اتصال الطبيب (Dr. Johnson)
- ⚙️ الإعدادات:
  - Notifications
  - Safe Zone Settings
  - Privacy & Security
  - Help & Support
- 🚪 Logout

---

## الشاشة الرئيسية 🏠

### Role Selection Screen
**الملف**: `lib/screens/role_selection_screen.dart`

**المحتوى**:
- 🧠 شعار AlzCare
- 📝 Compassionate Care for Alzheimer's Patients
- 3 أزرار:
  - 👤 Patient Portal
  - 👨‍⚕️ Doctor Portal
  - 👨‍👩‍👧 Family Member Portal

**التصميم**:
- خلفية gradien ناعمة
- بطاقة بيضاء مركزية
- أزرار كبيرة واضحة

---

## المكونات المشتركة 🧩

### StatCard
**الملف**: `lib/widgets/stat_card.dart`

**الاستخدام**:
```dart
StatCard(
  icon: Icons.psychology,
  label: 'Activities',
  value: '12/15',
  color: AppTheme.teal500,
  backgroundColor: AppTheme.teal50,
)
```

---

### ProgressItem
**الملف**: `lib/widgets/progress_item.dart`

**الاستخدام**:
```dart
ProgressItem(
  label: 'Face Recognition',
  value: 0.85,
  color: AppTheme.teal500,
)
```

---

## نظام الألوان 🎨

```dart
// Primary Colors
AppTheme.teal500      // #14B8A6
AppTheme.cyan500      // #06B6D4

// Gradients
AppTheme.tealGradient // Teal → Cyan
AppTheme.lightGradient // Cyan50 → White → Teal50

// Backgrounds
AppTheme.teal50       // Light background
AppTheme.cyan50       // Light background
Colors.white          // Cards
```

---

## نظام الملاحة 🧭

### Patient Navigation (5 tabs)
1. Home
2. Activities
3. Tracking
4. Chat
5. Profile

### Doctor Navigation (6 tabs)
1. Dashboard
2. Advice
3. Activities
4. Tracking
5. Chat
6. Profile

### Family Navigation (4 tabs)
1. Dashboard
2. Tracking
3. Chat
4. Profile

---

## الملخص 📊

| الواجهة | عدد الشاشات | الميزات الرئيسية |
|---------|-------------|------------------|
| **المريض** | 5 | Activities, Tracking, Chat |
| **الطبيب** | 6 | Management, Advice, Multi-tracking |
| **العائلة** | 4 | Monitoring, 3-mode Tracking, Chat |
| **المجموع** | **15** | **Complete Care System** |

---

**تم بناء جميع الشاشات بتصميم متجاوب ومتناسق** ✨
