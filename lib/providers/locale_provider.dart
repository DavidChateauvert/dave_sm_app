import 'package:flutter/material.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = Locale('en');

  Locale get locale => _locale;

  set locale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void toggleLocale() {
    if (_locale == Locale('en')) {
      locale = Locale('fr');
    } else {
      locale = Locale('en');
    }
  }

  void selectIntro(int index) {
    if (index == 0) {
      locale = Locale('en');
    } else {
      locale = Locale('fr');
    }
  }

  void toggleLocaleToParam(String theme) {
    if (theme == "en") {
      locale = Locale('en');
    } else {
      locale = Locale('fr');
    }
  }

  String getLocaleFormatString() {
    if (locale == Locale('en')) {
      return "en";
    } else {
      return "fr";
    }
  }
}
