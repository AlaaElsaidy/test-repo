# AlzCare - Flutter Mobile Application

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
</div>

## 📱 About

**AlzCare** is a comprehensive mobile application designed to provide compassionate care and support for Alzheimer's patients, their families, and healthcare providers. Built with Flutter for cross-platform compatibility (iOS & Android).

### ✨ Key Features

#### 🏥 Patient Interface
- **Dashboard**: Daily overview with memory progress, appointments, and reminders
- **Memory Activities**: Interactive exercises (Face Recognition, Photo Memory, Music Therapy, Story Recall)
- **Live Tracking**: Real-time location monitoring with safe zones
- **Chat with Doctor**: Direct messaging with healthcare providers
- **Profile Management**: Personal information and emergency contacts

#### 👨‍⚕️ Doctor Interface
- **Dashboard**: Patient overview, appointments, and chat requests
- **Advice Management**: Create and manage care articles
- **Activities Management**: Assign and track patient activities
- **Live Tracking**: Monitor all patients on map with safety status
- **Chat System**: Multi-patient messaging
- **Profile**: Professional information and reviews

#### 👨‍👩‍👧 Family Interface
- **Dashboard**: Patient status, progress, and quick actions
- **Family Circle**: Manage family members and caregivers
- **Chat**: Message doctor and patient
- **Profile**: Caregiver information and care statistics

## 🎨 Design

- **Color Scheme**: Teal (#14B8A6) and Cyan (#06B6D4)
- **UI Style**: Modern healthcare design with smooth gradients and rounded corners
- **Mood**: Warm, secure, and supportive

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / Xcode (for iOS)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/alzcare.git
   cd alzcare/flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Build for Production

**Android (APK)**
```bash
flutter build apk --release
```

**Android (App Bundle)**
```bash
flutter build appbundle --release
```

**iOS**
```bash
flutter build ios --release
```

## 📁 Project Structure

```
flutter/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── theme/
│   │   └── app_theme.dart            # Colors and theme configuration
│   ├── screens/
│   │   ├── role_selection_screen.dart # Initial role selection
│   │   ├── patient/                   # Patient screens
│   │   │   ├── patient_main_screen.dart
│   │   │   ├── patient_dashboard.dart
│   │   │   ├── memory_activities_screen.dart
│   │   │   ├── live_tracking_screen.dart
│   │   │   ├── chat_with_doctor_screen.dart
│   │   │   └── patient_profile_screen.dart
│   │   ├── doctor/                    # Doctor screens
│   │   │   └── doctor_main_screen.dart
│   │   └── family/                    # Family screens
│   │       └── family_main_screen.dart
│   └── widgets/                       # Reusable widgets
│       ├── stat_card.dart
│       └── progress_item.dart
├── pubspec.yaml                       # Dependencies
└── README.md                          # This file
```

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1              # State management
  font_awesome_flutter: ^10.6.0 # Icons
  go_router: ^12.1.3            # Navigation
  http: ^1.1.2                  # API calls
  shared_preferences: ^2.2.2    # Local storage
  google_maps_flutter: ^2.5.0   # Maps
  geolocator: ^10.1.0           # Location
  fl_chart: ^0.65.0             # Charts
  cached_network_image: ^3.3.1  # Image caching
```

## 🔧 Configuration

### API Configuration
Update the API endpoints in `lib/config/api_config.dart` (to be created):

```dart
class ApiConfig {
  static const String baseUrl = 'https://your-api.com';
  static const String doctorEndpoint = '/api/doctors';
  static const String patientEndpoint = '/api/patients';
  // Add more endpoints as needed
}
```

### Google Maps Setup

1. **Android**: Add your API key in `android/app/src/main/AndroidManifest.xml`
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY_HERE"/>
   ```

2. **iOS**: Add your API key in `ios/Runner/AppDelegate.swift`
   ```swift
   GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
   ```

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 📱 Screenshots

| Patient Dashboard | Memory Activities | Live Tracking |
|------------------|------------------|---------------|
| Dashboard with progress tracking | Interactive memory games | Real-time location monitoring |

| Doctor Dashboard | Activities Management | Family Dashboard |
|-----------------|---------------------|-----------------|
| Patient overview | Assign and track activities | Care monitoring |

## 🌐 Supported Platforms

- ✅ Android (5.0+)
- ✅ iOS (12.0+)

## 👥 Team

- **UI/UX Design**: Modern healthcare-focused design
- **Development**: Flutter/Dart cross-platform
- **Backend**: (To be integrated)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

For support, email support@alzcare.com or join our Slack channel.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Healthcare professionals who provided insights
- Alzheimer's caregivers for their feedback

---

<div align="center">
  Made with ❤️ for Alzheimer's care
</div>
