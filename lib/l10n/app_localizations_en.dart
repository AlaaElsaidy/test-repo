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
  String get cancel => 'Canceled';

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
  String get email => 'E-mail';

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
  String get confirmPassword => 'ConfirmPassword';

  @override
  String get next => 'Next';

  @override
  String get passwordMatch => 'The password doesn\'t match';

  @override
  String get allDone => 'All Done!';

  @override
  String get returnToLoginPage => 'Return to Login Page';
}
