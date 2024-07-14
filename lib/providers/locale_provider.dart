import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';

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

  List<bool> defaultBoolList() {
    if (_locale == Locale('fr')) {
      return [
        false,
        true,
      ];
    } else {
      return [
        true,
        false,
      ];
    }
  }

  void selectIntro(int index) {
    if (index == 0) {
      locale = Locale('en');
    } else {
      locale = Locale('fr');
    }
  }

  void toggleLocaleToParam(String localeString, bool changeInFirestore) async {
    if (localeString == "en") {
      locale = Locale('en');
    } else {
      locale = Locale('fr');
    }
    await usersRef.doc(currentUser.id).update({
      "locale": localeString,
    });
  }

  String getLocaleFormatString() {
    if (locale == Locale('en')) {
      return "en";
    } else {
      return "fr";
    }
  }

  Locale getLocaleFromString(String localeString) {
    if (localeString == "fr") {
      return Locale('fr');
    } else {
      return Locale('en');
    }
  }
}
