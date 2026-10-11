import 'package:flutter/material.dart';
import 'colors.dart';

class ArgusTheme {
  ArgusTheme._();

  static const String fontFamily = 'MatrixSans';

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ArgusColors.background,
        fontFamily: fontFamily,
        colorScheme: const ColorScheme.dark(
          primary: ArgusColors.green,
          secondary: ArgusColors.green,
          error: ArgusColors.red,
          surface: ArgusColors.panel,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: ArgusColors.green, fontSize: 14),
          bodySmall: TextStyle(color: ArgusColors.grey, fontSize: 12),
          titleLarge: TextStyle(color: ArgusColors.white, fontSize: 20),
          labelLarge: TextStyle(color: ArgusColors.green, fontSize: 16),
        ),
      );
}