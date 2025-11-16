import 'package:alzcare/config/router/routes.dart';
import 'package:flutter/material.dart';

import '../../login/presentation/pages/login.dart';
import '../../screens/doctor/doctor_main_screen(1).dart';
import '../../screens/family/doctors-selection/presentation/pages/doctorScreen.dart';
import '../../screens/family/family_main_screen.dart';
import '../../screens/family/payment/presentation/pages/payment-screen.dart';
import '../../screens/family/service/pages/service-screen.dart';
import '../../screens/family/signup/presentation/pages/sign-up.dart';
import '../../screens/patient/patient-details/presentation/pages/patient-details-screen.dart';
import '../../screens/patient/patient_main_screen.dart';
import '../../screens/role_selection_screen.dart';

class AppRouter {
  static Route onGenerate(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (context) => const SignInScreen());
      case AppRoutes.welcome:
        return MaterialPageRoute(
            builder: (context) => const RoleSelectionScreen());

      case AppRoutes.signUp:
        return MaterialPageRoute(builder: (context) => const SignUpScreen());
      case AppRoutes.doctorSelection:
        return MaterialPageRoute(
            builder: (context) => const DoctorSelectionScreen());

      case AppRoutes.patientDetails:
        return MaterialPageRoute(
            builder: (context) => const PatientDetailsScreen());
      case AppRoutes.patientMain:
        return MaterialPageRoute(
            builder: (context) => const PatientMainScreen());
      case AppRoutes.familyMain:
        return MaterialPageRoute(
            builder: (context) => const FamilyMainScreen());

      case AppRoutes.doctorMain:
        return MaterialPageRoute(
            builder: (context) => const DoctorMainScreen());

      case AppRoutes.service:
        return MaterialPageRoute(builder: (context) => const ServiceScreen());

      case AppRoutes.paymentDetails:
        return MaterialPageRoute(
            builder: (context) => const PaymentDetailsScreen());

      default:
        return MaterialPageRoute(builder: (context) => const SizedBox());
    }
  }
}
