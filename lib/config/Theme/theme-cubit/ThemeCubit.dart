import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../../../core/shared-prefrences/shared-prefrences-helper.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.dark);

  Future<void> loadTheme() async {
    final savedTheme = await SharedPrefsHelper.getString("theme");
    if (savedTheme == "light") {
      emit(ThemeMode.light);
    } else {
      emit(ThemeMode.dark);
    }
  }

  void toggleTheme() async {
    final newTheme =
        state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    emit(newTheme);
    await SharedPrefsHelper.saveString(
      "theme",
      newTheme == ThemeMode.dark ? "dark" : "light",
    );
  }
}
