import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    background: Colors.white,
    primary: Color.fromARGB(255, 89, 36, 99),
    primaryContainer: Color.fromARGB(255, 89, 36, 99),
    secondaryContainer: Colors.grey,
    secondary: Color.fromARGB(255, 244, 186, 184),
    onBackground: Colors.black,
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    background: Color.fromARGB(255, 47, 47, 47),
    primary: Color.fromARGB(255, 89, 36, 99),
    primaryContainer: Color.fromARGB(255, 244, 186, 184),
    secondaryContainer: Colors.grey,
    secondary: Color.fromARGB(255, 244, 186, 184),
    onBackground: Colors.white,
  ),
);
