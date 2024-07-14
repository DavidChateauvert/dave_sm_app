import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  set themeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }

  void toggleThemeMode(String theme, bool changeInFirestore) async {
    if (theme == "dark") {
      themeMode = ThemeMode.dark;
    } else if (theme == "light") {
      themeMode = ThemeMode.light;
    } else {
      themeMode = ThemeMode.system;
    }
    if (changeInFirestore) {
      await usersRef.doc(currentUser.id).update({
        "theme": theme,
      });
    }
  }

  List<bool> defaultBoolList() {
    if (_themeMode == ThemeMode.dark) {
      return [false, false, true];
    } else if (_themeMode == ThemeMode.light) {
      return [false, true, false];
    } else {
      return [true, false, false];
    }
  }

  String getThemeModeFormatString() {
    switch (themeMode) {
      case ThemeMode.dark:
        return "dark";
      case ThemeMode.light:
        return "light";
      case ThemeMode.system:
      default:
        return "system";
    }
  }
}
