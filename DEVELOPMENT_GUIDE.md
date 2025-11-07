# AlzCare - Flutter Development Guide

## 🏗️ Project Architecture

This Flutter application follows a **clean architecture** pattern with clear separation of concerns:

```
lib/
├── main.dart                 # App initialization
├── theme/                    # Theme and styling
├── screens/                  # UI screens (organized by role)
├── widgets/                  # Reusable components
├── models/                   # Data models (to be added)
├── services/                 # Business logic (to be added)
└── utils/                    # Helper functions (to be added)
```

## 🎨 Theme System

### Colors
All colors are defined in `lib/theme/app_theme.dart`:

```dart
// Primary Colors
AppTheme.teal500    // Main teal color
AppTheme.cyan500    // Main cyan color

// Backgrounds
AppTheme.teal50     // Light teal background
AppTheme.cyan50     // Light cyan background

// Gradients
AppTheme.tealGradient      // Teal to cyan gradient
AppTheme.lightGradient     // Background gradient
```

### Using Theme Colors

```dart
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.tealGradient,
    borderRadius: BorderRadius.circular(16),
  ),
)
```

## 📱 Screen Development

### Creating a New Screen

1. **Create the file** in appropriate directory:
   ```
   lib/screens/[role]/[screen_name]_screen.dart
   ```

2. **Basic structure**:
   ```dart
   import 'package:flutter/material.dart';
   import '../../theme/app_theme.dart';

   class MyNewScreen extends StatelessWidget {
     const MyNewScreen({super.key});

     @override
     Widget build(BuildContext context) {
       return SafeArea(
         child: SingleChildScrollView(
           padding: const EdgeInsets.all(16),
           child: Column(
             children: [
               // Your widgets here
             ],
           ),
         ),
       );
     }
   }
   ```

### Navigation

```dart
// Push to new screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const NewScreen(),
  ),
);

// Pop back
Navigator.pop(context);
```

## 🔧 Common Widgets

### Gradient Header Card

```dart
Container(
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    gradient: AppTheme.tealGradient,
    borderRadius: BorderRadius.circular(24),
  ),
  child: Column(
    children: [
      Text(
        'Title',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      // More widgets...
    ],
  ),
)
```

### Info Card with Icon

```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.teal50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.favorite,
            color: AppTheme.teal600,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title'),
              Text('Subtitle'),
            ],
          ),
        ),
      ],
    ),
  ),
)
```

## 🎯 State Management

### Using StatefulWidget

```dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Count: $_counter'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

## 🔌 API Integration (Future Implementation)

### Service Structure

```dart
// lib/services/patient_service.dart
class PatientService {
  static const String baseUrl = 'https://api.alzcare.com';

  Future<Patient> getPatientInfo(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/patients/$id'),
    );
    
    if (response.statusCode == 200) {
      return Patient.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load patient');
    }
  }
}
```

### Model Structure

```dart
// lib/models/patient.dart
class Patient {
  final String id;
  final String name;
  final int age;
  final String stage;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.stage,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      stage: json['stage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'stage': stage,
    };
  }
}
```

## 🧪 Testing

### Widget Tests

```dart
// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:alzcare/screens/role_selection_screen.dart';

void main() {
  testWidgets('Role selection has three buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: RoleSelectionScreen()),
    );

    expect(find.text('Patient Portal'), findsOneWidget);
    expect(find.text('Doctor Portal'), findsOneWidget);
    expect(find.text('Family Member Portal'), findsOneWidget);
  });
}
```

## 📦 Adding New Dependencies

1. Add to `pubspec.yaml`:
   ```yaml
   dependencies:
     new_package: ^1.0.0
   ```

2. Run:
   ```bash
   flutter pub get
   ```

3. Import in your file:
   ```dart
   import 'package:new_package/new_package.dart';
   ```

## 🚀 Performance Tips

1. **Use const constructors** whenever possible
2. **Lazy load** images with `CachedNetworkImage`
3. **Avoid rebuilding** widgets unnecessarily
4. **Use ListView.builder** for long lists
5. **Profile your app** with Flutter DevTools

## 🐛 Debugging

### Common Commands

```bash
# Check for issues
flutter analyze

# Format code
flutter format .

# Clean build
flutter clean
flutter pub get

# Run with logging
flutter run -v
```

### Debug Mode Features

- Hot reload: Press `r` in terminal
- Hot restart: Press `R` in terminal
- Toggle performance overlay: Press `P`

## 📝 Code Style

Follow these conventions:

1. **Naming**:
   - Classes: `PascalCase`
   - Variables/Functions: `camelCase`
   - Files: `snake_case.dart`
   - Constants: `SCREAMING_SNAKE_CASE`

2. **Formatting**:
   - Use 2 spaces for indentation
   - Max line length: 80 characters
   - Always use trailing commas

3. **Documentation**:
   ```dart
   /// Displays the patient dashboard with daily overview.
   /// 
   /// Shows memory progress, appointments, and reminders.
   class PatientDashboard extends StatelessWidget {
     // ...
   }
   ```

## 🔐 Security Best Practices

1. **Never commit** API keys or secrets
2. Use **environment variables** for sensitive data
3. Implement **proper authentication**
4. **Encrypt** local storage data
5. Use **HTTPS** for all API calls

## 📚 Useful Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Material Design](https://material.io/design)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and format code
4. Submit a pull request

---

Happy Coding! 🎉
