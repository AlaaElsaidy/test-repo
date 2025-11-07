import 'package:alzcare/config/router/routes.dart';
import 'package:flutter/material.dart';

import '../../login/pages/login.dart';
import '../../screens/patient/patient-details/pages/patient-details-screen.dart';
import '../../screens/patient/payment/pages/done-screen.dart';
import '../../screens/patient/payment/pages/payment-screen.dart';
import '../../screens/patient/service/pages/service-screen.dart';
import '../../screens/patient/signup/pages/sign-up.dart';
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

      case AppRoutes.patientDetails:
        return MaterialPageRoute(
            builder: (context) => const PatientDetailsScreen());

      case AppRoutes.service:
        return MaterialPageRoute(builder: (context) => const ServiceScreen());
      case AppRoutes.done:
        return MaterialPageRoute(builder: (context) => const Done());

      case AppRoutes.paymentDetails:
        return MaterialPageRoute(
            builder: (context) => const PaymentDetailsScreen());

      default:
        return MaterialPageRoute(builder: (context) => const SizedBox());
    }
  }
}
