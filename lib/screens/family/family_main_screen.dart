// import 'package:flutter/material.dart';
// import '../../theme/app_theme.dart';
// import 'family_dashboard.dart';
// import 'family_tracking_screen.dart';
// import 'family_chat_screen.dart';
// import 'family_profile_screen.dart';

// class FamilyMainScreen extends StatefulWidget {
//   const FamilyMainScreen({super.key});

//   @override
//   State<FamilyMainScreen> createState() => _FamilyMainScreenState();
// }

// class _FamilyMainScreenState extends State<FamilyMainScreen> {
//   int _currentIndex = 0;

//   final List<Widget> _screens = [
//     const FamilyDashboard(),
//     const FamilyTrackingScreen(),
//     const FamilyChatScreen(),
//     const FamilyProfileScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: AppTheme.lightGradient,
//         ),
//         child: _screens[_currentIndex],
//       ),
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//             ),
//           ],
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildNavItem(0, Icons.home, 'Dashboard'),
//                 _buildNavItem(1, Icons.location_on, 'Tracking'),
//                 _buildNavItem(2, Icons.chat, 'Chat'),
//                 _buildNavItem(3, Icons.person, 'Profile'),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem(int index, IconData icon, String label) {
//     final isSelected = _currentIndex == index;

//     return InkWell(
//       onTap: () => setState(() => _currentIndex = index),
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: isSelected ? AppTheme.teal50 : Colors.transparent,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               color: isSelected ? AppTheme.teal600 : AppTheme.gray500,
//               size: 24,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 11,
//                 color: isSelected ? AppTheme.teal600 : AppTheme.gray500,
//                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/notification_listener_widget.dart';
import './family_activities_screen.dart';
import 'family_chat_screen.dart';
import 'family_dashboard.dart';
import 'family_profile_screen.dart';
import 'family_tracking_screen.dart';

class FamilyMainScreen extends StatefulWidget {
  const FamilyMainScreen({super.key});

  @override
  State<FamilyMainScreen> createState() => _FamilyMainScreenState();
}

class _FamilyMainScreenState extends State<FamilyMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FamilyDashboard(),
    const FamilyTrackingScreen(),
    const FamilyChatScreen(),
    const FamilyProfileScreen(),
    const FamilyActivitiesScreen()
  ];

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2);

    return NotificationListenerWidget(
      showSnackBar: true,
      showDialog: true,
      onNotification: (notification) {
        // يمكنك إضافة منطق إضافي هنا عند استلام إشعار
        debugPrint('Received notification: ${notification.type}');
      },
      child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.lightGradient,
        ),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home, 'Home', textScale),
                _buildNavItem(1, Icons.location_on, 'Tracking', textScale),
                _buildNavItem(4, Icons.psychology, 'Activities', textScale),
                _buildNavItem(2, Icons.chat, 'Chat', textScale),
                _buildNavItem(3, Icons.person, 'Profile', textScale),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    double textScale,
  ) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.teal50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.teal600 : AppTheme.gray500,
              size: 22 * textScale,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10 * textScale,
                  color: isSelected ? AppTheme.teal600 : AppTheme.gray500,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}