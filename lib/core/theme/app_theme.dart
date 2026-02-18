import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF6750A4),
    brightness: Brightness.light,
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF6750A4),
    brightness: Brightness.dark,
  );
}
