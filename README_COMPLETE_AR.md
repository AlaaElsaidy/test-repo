# 🏥 AlzCare - تطبيق رعاية مرضى الزهايمر الشامل

<div dir="rtl">

## 🌟 نظرة عامة

تطبيق Flutter كامل ومتكامل لرعاية مرضى الزهايمر، يوفر **15 شاشة** موزعة على **3 واجهات** مختلفة (المريض، الطبيب، العائلة).

### ✨ الميزات الرئيسية

- 🧠 **أنشطة تذكيرية** تفاعلية مع نظام نقاط
- 📍 **تتبع GPS مباشر** مع 3 أوضاع (Live, Safe Zones, History)
- 💬 **محادثات فورية** بين جميع المستخدمين
- 📚 **مكتبة نصائح** شاملة (Handling, Support, Tips)
- 📊 **لوحات تحكم** متطورة لكل نوع مستخدم
- 🎨 **تصميم عصري** بألوان Teal & Cyan

---

## 🚀 البدء السريع

### المتطلبات
```bash
Flutter SDK ≥ 3.0.0
Dart SDK ≥ 3.0.0
```

### التثبيت والتشغيل
```bash
# 1. الانتقال لمجلد المشروع
cd flutter

# 2. تثبيت الحزم
flutter pub get

# 3. تشغيل التطبيق
flutter run
```

### الأوامر المفيدة
```bash
flutter clean              # تنظيف المشروع
flutter doctor            # فحص المشاكل
flutter build apk         # بناء APK
flutter run -d chrome     # تشغيل على المتصفح
```

---

## 📱 الواجهات والشاشات (15 شاشة)

### 👤 واجهة المريض (5 شاشات)

#### 1. Patient Dashboard
- 👋 ترحيب شخصي مع الإحصائيات
- 📊 تقدم الذاكرة (Face Recognition, Photo Matching, Music)
- 📅 الموعد القادم مع الطبيب
- ⏰ تذكيرات اليوم
- 🛡️ حالة الموقع والأمان

#### 2. Memory Activities
- 🎯 عرض التقدم اليومي (4/7 Activities)
- 📋 أنشطة تفاعلية:
  - Face Recognition (Easy - 50 pts)
  - Photo Memory (Medium - 75 pts)
  - Music Memories (Easy - 60 pts)
  - Story Recall (Hard - 100 pts)
- ✅ علامات الإنجاز
- 🏆 نظام نقاط

#### 3. Live Tracking
- 🗺️ خريطة توضيحية للموقع
- 📍 الموقع الحالي (123 Oak Street)
- 🟢 مؤشر المنطقة الآمنة
- 🔄 تحديث فوري
- 🚨 زر تنبيه الطوارئ

#### 4. Chat with Doctor
- 💬 محادثة ثنائية مع الطبيب
- 🟢 حالة الاتصال (Online)
- 📞 مكالمة صوتية
- 📹 مكالمة مرئية
- 📎 إرفاق ملفات وصور
- 😊 إيموجي

#### 5. Patient Profile
- 👤 معلومات شخصية كاملة
- 🏥 المرحلة المرضية (Early Alzheimer's)
- 🚨 جهة اتصال الطوارئ
- ⚙️ الإعدادات والخصوصية

---

### 👨‍⚕️ واجهة الطبيب (6 شاشات)

#### 1. Doctor Dashboard
- 📊 إحصائيات (24 Active Patients, 8 Appointments)
- 📅 مواعيد اليوم مع التفاصيل
- ⚠️ تنبيهات المرضى الذين يحتاجون انتباه
- 🔔 آخر أنشطة المرضى
- 🎯 نظرة شاملة على الحالات

#### 2. Advice & Resources
- 🔍 بحث في المقالات
- 🏷️ تصنيفات (All, Handling, Support, Tips)
- ⭐ مقال مميز
- 📚 مقالات شائعة:
  - Understanding Memory Loss Stages
  - Local Support Groups
  - Self-Care Tips for Caregivers
  - Managing Sundown Syndrome
  - Communication Strategies
  - Online Support Communities

#### 3. Activities Management
- 👤 اختيار المريض من قائمة
- 📊 إحصائيات الأنشطة (Active: 12, Completed: 8)
- 📋 أنشطة اليوم مع الحالة:
  - ✅ Completed
  - ⏳ Pending
  - 📅 Scheduled
- 📑 قوالب جاهزة:
  - Memory Games
  - Physical Activities
  - Social Engagement
- ➕ إضافة أنشطة جديدة

#### 4. Live Tracking (Multi-Patient)
- 📋 اختيار المريض من قائمة منسدلة
- 🗺️ خريطة توضيحية
- 🟢 حالة كل مريض (Safe/Alert)
- 📍 آخر موقع معروف
- 🧭 Get Directions
- 📜 History
- ⚙️ إدارة Safe Zones:
  - Home (200m)
  - Park (150m)
  - Hospital (100m)
  - ➕ Add New Zone

#### 5. Doctor Chat
- 📑 3 تبويبات:
  - Patients
  - Families
  - Groups
- 💬 قائمة محادثات منظمة
- 🔴 مؤشرات الرسائل غير المقروءة
- 🟢 حالة الاتصال
- 🔍 بحث في المحادثات

#### 6. Doctor Profile
- 👨‍⚕️ Dr. Sarah Johnson
- 🎓 Neurologist - Alzheimer's Specialist
- 📊 إحصائيات (156 Total Cases)
- 📞 معلومات الاتصال
- ⚙️ إعدادات:
  - Notifications
  - Working Hours
  - Privacy & Security
  - Help & Support

---

### 👨‍👩‍👧 واجهة العائلة (4 شاشات)

#### 1. Family Dashboard
- 👋 Hello, Emily (Caring for Margaret)
- 🟢 Everything is going well today
- 📊 Current Status:
  - 📍 At Home
  - 🎯 8/12 Activities Completed
- ⚡ أزرار سريعة:
  - View Location
  - Chat
- 📅 جدول اليوم الكامل
- 💡 Tip of the Day
- 🚨 Emergency Contact

#### 2. Family Tracking (3 أوضاع متقدمة)

**🔴 Live Tracking Mode**
- 🗺️ خريطة في الوقت الفعلي
- 📍 الموقع الحالي (123 Oak Street)
- 🟢 Safe Zone indicator
- 🔄 Refresh every few seconds
- 🧭 **Get Directions to Patient** (ميزة جديدة!)
- ⏱️ Last updated: Just now

**🛡️ Safe Zones Mode**
- 🏠 Home (200m - Active - ✅ Inside)
- 🌳 Park (150m - Active)
- 🏥 Hospital (100m - Active)
- ⛪ Church (100m - Inactive)
- تفعيل/تعطيل كل منطقة
- عرض نطاق (Radius) كل منطقة

**📜 History Mode**
- 🏠 Home (2 mins ago - Current)
- 🌳 Park (2 hours ago - 45 min duration)
- 🏥 Hospital (Yesterday - 2 hours)
- 🛍️ Shopping Center (2 days ago - 1 hour)
- عرض المدة الزمنية في كل مكان
- أيقونات مميزة لكل نوع مكان

#### 3. Family Chat
- 💬 محادثة مع المريض
- 📊 شريط معلومات سريع:
  - 📍 At Home
  - ✅ 8/12 Activities
  - ❤️ Feeling Good
- 📞 مكالمة صوتية
- 📹 مكالمة مرئية
- 📎 إرفاق ملفات
- 😊 إيموجي

#### 4. Family Profile
- 👤 Emily Smith - Daughter & Primary Caregiver
- 🔗 Caring for Margaret Smith
- 📋 معلومات المريض
- 🩺 اتصال سريع بالطبيب
- ⚙️ إعدادات متقدمة:
  - Notifications
  - **Safe Zone Settings** (جديد!)
  - Privacy & Security
  - Help & Support (Caregiver assistance)

---

## 🗺️ ميزات التتبع المحسّنة

### ✅ Live Tracking
- عرض الموقع في الوقت الفعلي
- تحديث تلقائي كل ثوان
- مؤشر المنطقة الآمنة
- حالة الأمان (Safe/Alert)

### 🛡️ Safe Zones
- إضافة مناطق آمنة غير محدودة
- تحديد نطاق (Radius) مخصص
- تفعيل/تعطيل كل منطقة
- تنبيهات عند الخروج

### 📜 History
- سجل كامل للأماكن المزارة
- عرض المدة في كل مكان
- توقيت كل زيارة
- تصنيف الأماكن بالأيقونات

### 🧭 Get Directions
- الحصول على اتجاهات للمريض
- فتح تطبيق الخرائط مباشرة
- **ميزة حصرية لواجهة العائلة**

---

## 📚 ميزات النصائح والدعم

### 🎯 How to Handle Situations
- Understanding Memory Loss Stages
- Managing Sundown Syndrome
- Dealing with Difficult Behaviors
- Communication Strategies
- Safety at Home

### 👥 Support Groups
- Local Support Groups Near You
- Online Support Communities
- Family Support Networks
- Caregiver Meetups
- Professional Support Services

### 💝 Caregiver Tips
- Self-Care Tips for Caregivers
- Managing Caregiver Stress
- Daily Routine Tips
- Nutrition and Exercise
- Respite Care Options

---

## 🎨 نظام التصميم

### الألوان الأساسية
```dart
Primary Teal:   #14B8A6  // اللون الأساسي
Teal Dark:      #0D9488  // للنصوص الداكنة
Primary Cyan:   #06B6D4  // اللون الثانوي
Cyan Light:     #22D3EE  // للتدرجات
```

### الخلفيات
```dart
White:          #FFFFFF  // البطاقات
Teal 50:        #F0FDFA  // خلفية فاتحة
Cyan 50:        #ECFEFF  // خلفية فاتحة
Gray 50:        #F9FAFB  // خلفية محايدة
```

### التدرجات
```dart
tealGradient:   [Teal500 → Cyan500]
lightGradient:  [Cyan50 → White → Teal50]
```

### الزوايا والظلال
- Border Radius: 16px (البطاقات)
- Border Radius: 12px (الأزرار)
- Border Radius: 24px (البطاقات الكبيرة)
- Box Shadow: Soft, 0.05 opacity

---

## 📦 الحزم المستخدمة

```yaml
dependencies:
  # Core
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.1
  
  # Navigation
  go_router: ^12.1.3
  
  # Network & API
  http: ^1.1.2
  
  # Storage
  shared_preferences: ^2.2.2
  
  # Location & Maps
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  
  # UI Components
  fl_chart: ^0.65.0
  cached_network_image: ^3.3.1
  font_awesome_flutter: ^10.6.0
  
  # Icons
  cupertino_icons: ^1.0.6
```

---

## 📂 بنية المشروع

```
flutter/
├── lib/
│   ├── main.dart                           # Entry point
│   │
│   ├── theme/
│   │   └── app_theme.dart                  # Colors & Theme
│   │
│   ├── screens/
│   │   ├── role_selection_screen.dart      # Main screen
│   │   │
│   │   ├── patient/                        # 5 screens
│   │   │   ├── patient_main_screen.dart
│   │   │   ├── patient_dashboard.dart
│   │   │   ├── memory_activities_screen.dart
│   │   │   ├── live_tracking_screen.dart
│   │   │   ├── chat_with_doctor_screen.dart
│   │   │   └── patient_profile_screen.dart
│   │   │
│   │   ├── doctor/                         # 6 screens
│   │   │   ├── doctor_main_screen.dart
│   │   │   ├── doctor_dashboard.dart
│   │   │   ├── doctor_advice_screen.dart
│   │   │   ├── doctor_activities_screen.dart
│   │   │   ├── doctor_tracking_screen.dart
│   │   │   ├── doctor_chat_screen.dart
│   │   │   └── doctor_profile_screen.dart
│   │   │
│   │   └── family/                         # 4 screens
│   │       ├── family_main_screen.dart
│   │       ├── family_dashboard.dart
│   │       ├── family_tracking_screen.dart
│   │       ├── family_chat_screen.dart
│   │       └── family_profile_screen.dart
│   │
│   └── widgets/
│       ├── stat_card.dart                  # Reusable stat card
│       └── progress_item.dart              # Progress indicator
│
├── pubspec.yaml                            # Dependencies
│
├── README_COMPLETE_AR.md                   # هذا الملف
├── FLUTTER_SETUP_AR.md                     # دليل شامل
├── QUICK_START_AR.md                       # بدء سريع
└── SCREENS_OVERVIEW_AR.md                  # نظرة على الشاشات
```

---

## 🔧 دليل التطوير

### إضافة شاشة جديدة

1. **إنشاء ملف الشاشة**
```dart
// lib/screens/patient/new_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NewScreen extends StatelessWidget {
  const NewScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: // محتوى الشاشة
    );
  }
}
```

2. **إضافتها للـ navigation**
```dart
// في patient_main_screen.dart
final List<Widget> _screens = [
  const PatientDashboard(),
  // ... الشاشات الأخرى
  const NewScreen(),  // شاشتك الجديدة
];
```

### استخدام الألوان
```dart
// خلفية تدرج
Container(
  decoration: const BoxDecoration(
    gradient: AppTheme.tealGradient,
  ),
)

// بطاقة ملونة
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: AppTheme.teal50,
    borderRadius: BorderRadius.circular(16),
  ),
)
```

### إنشاء بطاقة
```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        // محتوى البطاقة
      ],
    ),
  ),
)
```

---

## 🧪 الاختبار والبناء

### اختبار التطبيق
```bash
# تشغيل على محاكي Android
flutter run

# تشغيل على iOS (Mac only)
flutter run -d ios

# تشغيل على Chrome
flutter run -d chrome

# Hot Reload
r (في terminal أثناء التشغيل)

# Hot Restart
R (في terminal أثناء التشغيل)
```

### بناء للإنتاج
```bash
# Android APK
flutter build apk --release

# Android App Bundle (للنشر على Play Store)
flutter build appbundle --release

# iOS (Mac only)
flutter build ios --release
```

### فحص المشاكل
```bash
flutter doctor
flutter clean
flutter pub get
```

---

## 📊 ملخص الإحصائيات

| البند | العدد |
|------|------|
| إجمالي الشاشات | 15 |
| شاشات المريض | 5 |
| شاشات الطبيب | 6 |
| شاشات العائلة | 4 |
| المكونات المشتركة | 2 |
| أوضاع التتبع | 3 |
| فئات النصائح | 3 |
| الحزم المستخدمة | 10+ |

---

## ✨ الميزات المتقدمة

### 🎯 نظام النقاط
- كل نشاط له نقاط محددة
- تتبع إجمالي النقاط
- مكافآت للإنجازات

### 📊 تتبع التقدم
- Face Recognition: 85%
- Photo Matching: 72%
- Music Memory: 90%

### 🔔 التنبيهات
- تنبيهات الأنشطة
- تنبيهات الموقع
- تنبيهات الطوارئ
- تنبيهات المواعيد

### 💬 نظام المحادثات
- محادثات فردية
- محادثات جماعية
- إرفاق ملفات
- إيموجي
- مكالمات صوتية/مرئية

---

## 🚨 ملاحظات مهمة

### ⚠️ تحذيرات الخصوصية
- 🔒 هذا تطبيق تجريبي/تعليمي
- 📋 لا يجب استخدامه لبيانات حقيقية
- 🏥 يتطلب الاستخدام الطبي معايير HIPAA
- 🔐 يجب تطبيق معايير أمان إضافية

### 📱 التوافق
- ✅ Android 5.0+
- ✅ iOS 12.0+
- ✅ Web (للاختبار فقط)

### 🔧 متطلبات الإنتاج
- نظام مصادقة آمن (Firebase Auth)
- قاعدة بيانات (Firestore/Supabase)
- خوادم API آمنة
- تشفير البيانات
- نسخ احتياطي تلقائي

---

## 📚 موارد إضافية

### وثائق Flutter
- [Flutter Documentation](https://docs.flutter.dev)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Widget Catalog](https://docs.flutter.dev/development/ui/widgets)

### التصميم
- [Material Design](https://material.io/design)
- [Flutter Layout Guide](https://docs.flutter.dev/development/ui/layout)
- [Color Tool](https://material.io/resources/color)

### الحزم
- [pub.dev](https://pub.dev) - مكتبة حزم Dart و Flutter

---

## 🤝 المساهمة

نرحب بالمساهمات! للمساهمة:

1. Fork المشروع
2. إنشاء branch جديد (`git checkout -b feature/amazing-feature`)
3. Commit التغييرات (`git commit -m 'Add amazing feature'`)
4. Push للـ branch (`git push origin feature/amazing-feature`)
5. فتح Pull Request

---

## 📧 التواصل والدعم

- للإبلاغ عن مشكلة: افتح Issue على GitHub
- للاستفسارات: راجع الوثائق أولاً
- للمساهمات: اتبع دليل المساهمة

---

## 📄 الترخيص

هذا المشروع مرخص تحت رخصة MIT - انظر ملف LICENSE للتفاصيل.

---

## 🙏 شكر وتقدير

- Flutter Team للإطار الرائع
- Material Design للتصميم
- المجتمع المفتوح المصدر

---

## 📅 الإصدارات

### v1.0.0 (Current)
- ✅ 15 شاشة كاملة
- ✅ 3 واجهات منفصلة
- ✅ تتبع GPS متقدم (3 أوضاع)
- ✅ نظام نصائح شامل
- ✅ محادثات فورية
- ✅ تصميم متجاوب

---

<div align="center">

**تم بناء التطبيق بـ ❤️ باستخدام Flutter**

**AlzCare - Compassionate Care for Alzheimer's Patients**

🧠 💙 🏥

</div>

</div>
