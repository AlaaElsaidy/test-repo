// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get success => 'تم تسجيل الدخول بنجاح';

  @override
  String get noContent => 'لا يوجد محتوى';

  @override
  String get badRequest => 'طلب غير صالح';

  @override
  String get forbidden => 'ممنوع';

  @override
  String get unauthorised => 'غير مصرح';

  @override
  String get notFound => 'غير موجود';

  @override
  String get internalServerError => 'خطأ في الخادم';

  @override
  String get connectTimeout => 'انتهت مهلة الاتصال';

  @override
  String get connectionError => 'خطأ في الاتصال';

  @override
  String get cancel => 'إلغاء';

  @override
  String get receiveTimeout => 'انتهت مهلة الاستقبال';

  @override
  String get sendTimeout => 'انتهت مهلة الإرسال';

  @override
  String get cacheError => 'خطأ في الكاش';

  @override
  String get noInternetConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get defaultError => 'حدث خطأ ما';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'الرقم السري';

  @override
  String get welcome => 'أهلا بعودتك!';

  @override
  String get forgetPassword => 'هل نسيت كلمة السر؟';

  @override
  String get message => 'الرسالة:';

  @override
  String get ok => 'تم';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get passRequired => 'الرقم السري مطلوب';

  @override
  String get confirmMail => 'تأكيد البريد الإلكتروني';

  @override
  String get confirmMessage =>
      'يرجى كتابة بريدك الإلكتروني لتلقي رمز التأكيد لتعيين كلمة مرور جديدة.';

  @override
  String get verificationCode => 'رمز التحقق';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get next => 'التالي';

  @override
  String get passwordMatch => 'كلمة المرور لا تتطابق';

  @override
  String get allDone => 'تم بنجاح!';

  @override
  String get returnToLoginPage => 'الرجوع لصفحة تسجيل الدخول';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get doctorName => 'د. سارة جونسون';

  @override
  String get specialization => 'استشارية أعصاب - متخصصة ألزهايمر';

  @override
  String yearsExperience(int years) {
    return 'خبرة $years سنة';
  }

  @override
  String get activePatients => 'مرضى نشطون';

  @override
  String get totalCases => 'إجمالي الحالات';

  @override
  String get contactInformation => 'معلومات التواصل';

  @override
  String get edit => 'تعديل';

  @override
  String get phone => 'الهاتف';

  @override
  String get hospital => 'المستشفى';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get workingHours => 'ساعات العمل';

  @override
  String get privacySecurity => 'الخصوصية والأمان';

  @override
  String get helpSupport => 'المساعدة والدعم';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get language => 'اللغة';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get save => 'حفظ';

  @override
  String get editContactInfo => 'تعديل معلومات التواصل';

  @override
  String get changePasswordTitle => 'تغيير كلمة المرور';

  @override
  String get changePasswordMandatoryNote =>
      'لأمانك، يجب تعيين كلمة مرور جديدة قبل المتابعة.';

  @override
  String get newPassword => 'كلمة مرور جديدة';

  @override
  String get passwordTooShort => 'كلمة المرور يجب ألا تقل عن 8 أحرف';

  @override
  String get passwordsDontMatch => 'كلمتا المرور غير متطابقتين';
}
