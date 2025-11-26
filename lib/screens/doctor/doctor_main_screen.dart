// import 'package:flutter/material.dart';
// import '../../theme/app_theme.dart';
// import 'doctor_dashboard.dart';
// import 'doctor_advice_screen.dart';
// import 'doctor_activities_screen.dart';
// import 'doctor_tracking_screen.dart';
// import 'doctor_chat_screen.dart';
// import 'doctor_profile_screen.dart';

// class DoctorMainScreen extends StatefulWidget {
//   const DoctorMainScreen({super.key});

//   @override
//   State<DoctorMainScreen> createState() => _DoctorMainScreenState();
// }

// class _DoctorMainScreenState extends State<DoctorMainScreen> {
//   int _currentIndex = 0;

//   final List<Widget> _screens = [
//     const DoctorDashboard(),
//     const DoctorAdviceScreen(),
//     const DoctorActivitiesScreen(),
//     const DoctorTrackingScreen(),
//     const DoctorChatScreen(),
//     const DoctorProfileScreen(),
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
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildNavItem(0, Icons.dashboard, 'Dashboard'),
//                 _buildNavItem(1, Icons.article, 'Advice'),
//                 _buildNavItem(2, Icons.task_alt, 'Activities'),
//                 _buildNavItem(3, Icons.location_on, 'Tracking'),
//                 _buildNavItem(4, Icons.chat, 'Chat'),
//                 _buildNavItem(5, Icons.person, 'Profile'),
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
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
//               size: 22,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 10,
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
import 'doctor_advice_screen.dart';
import 'doctor_chat_screen.dart';
import 'doctor_dashboard.dart';
import 'profile/presentation/pages/doctor_profile_screen.dart';

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({super.key});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DoctorDashboard(),
    DoctorAdviceScreen(),
    DoctorChatScreen(),
    DoctorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final BoxDecoration backgroundDecoration = isDarkMode
        ? const BoxDecoration(color: Colors.black)
        : const BoxDecoration(gradient: AppTheme.lightGradient);
    final Color navBackground = theme.cardColor;
    final Color navShadow = Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05);
    final Color selectedColor =
        isDarkMode ? AppTheme.cyan100 : AppTheme.teal600;
    final Color unselectedColor =
        isDarkMode ? Colors.white70 : AppTheme.gray500;
    final Color highlightColor =
        isDarkMode ? Colors.white.withOpacity(0.08) : AppTheme.teal50;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBackground,
          boxShadow: [
            BoxShadow(
              color: navShadow,
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    0,
                    Icons.dashboard,
                    'Dashboard',
                    selectedColor,
                    unselectedColor,
                    highlightColor,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    1,
                    Icons.article,
                    'Advice',
                    selectedColor,
                    unselectedColor,
                    highlightColor,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    2,
                    Icons.chat,
                    'Chat',
                    selectedColor,
                    unselectedColor,
                    highlightColor,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    3,
                    Icons.person,
                    'Profile',
                    selectedColor,
                    unselectedColor,
                    highlightColor,
                  ),
                ),
              ],
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
    Color selectedColor,
    Color unselectedColor,
    Color highlightColor,
  ) {
    final isSelected = _currentIndex == index;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? highlightColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? selectedColor : unselectedColor,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? selectedColor : unselectedColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}