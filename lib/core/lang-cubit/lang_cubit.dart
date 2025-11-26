import 'dart:ui';

import 'package:bloc/bloc.dart';

import '../../core/shared-prefrences/shared-prefrences-helper.dart';

class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(const Locale('ar'));

  Future<void> loadLanguage() async {
    final saved = await SharedPrefsHelper.getString('language');
    if (saved != null && saved.isNotEmpty) {
      emit(Locale(saved));
    } else {
      emit(const Locale('ar'));
    }
  }

  Future<void> changeLanguage(String langCode) async {
    final newLocale = Locale(langCode);
    emit(newLocale);
    await SharedPrefsHelper.saveString('language', langCode);
  }
}
