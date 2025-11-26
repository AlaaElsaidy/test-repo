// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get success => 'Success';

  @override
  String get noContent => 'No content';

  @override
  String get badRequest => 'Bad request';

  @override
  String get forbidden => 'Forbidden';

  @override
  String get unauthorised => 'Unauthorised';

  @override
  String get notFound => 'Not found';

  @override
  String get internalServerError => 'Internal server error';

  @override
  String get connectTimeout => 'Connection timeout';

  @override
  String get connectionError => 'Connection error';

  @override
  String get cancel => 'Cancel';

  @override
  String get receiveTimeout => 'Receive timeout';

  @override
  String get sendTimeout => 'Send timeout';

  @override
  String get cacheError => 'Cache error';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get defaultError => 'Something went wrong';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get welcome => 'Welcome Back!';

  @override
  String get forgetPassword => 'Forget Password?';

  @override
  String get message => 'Message:';

  @override
  String get ok => 'Ok';

  @override
  String get emailRequired => 'Email is Required';

  @override
  String get passRequired => 'Password is Required';

  @override
  String get confirmMail => 'Confirm Mail';

  @override
  String get confirmMessage =>
      'Please write your email to receive a confirmation code to set a new password.';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get next => 'Next';

  @override
  String get passwordMatch => 'The password doesn\'t match';

  @override
  String get allDone => 'All Done!';

  @override
  String get returnToLoginPage => 'Return to Login Page';

  @override
  String get profile => 'Profile';

  @override
  String get doctorName => 'Dr. Sarah Johnson';

  @override
  String get specialization => 'Neurologist - Alzheimer\'s Specialist';

  @override
  String yearsExperience(int years) {
    return '$years years experience';
  }

  @override
  String get activePatients => 'Active Patients';

  @override
  String get totalCases => 'Total Cases';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get edit => 'Edit';

  @override
  String get phone => 'Phone';

  @override
  String get hospital => 'Hospital';

  @override
  String get notifications => 'Notifications';

  @override
  String get workingHours => 'Working Hours';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get save => 'Save';

  @override
  String get editContactInfo => 'Edit contact information';

  @override
  String get changePasswordTitle => 'Change your password';

  @override
  String get changePasswordMandatoryNote =>
      'For your security, please create a new password before you continue.';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordsDontMatch => 'Passwords don\'t match';
}
