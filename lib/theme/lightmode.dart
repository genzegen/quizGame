import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: Colors.grey.shade300,
    primary: Colors.grey.shade200,
    secondary: Colors.grey.shade800,
    tertiary: Colors.grey.shade500,
    inversePrimary: Colors.grey.shade900,
  ),
  textTheme: ThemeData.light().textTheme.apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
);
