import 'package:flutter/material.dart';

/// ألوان مطبخي كما في ملف Figma (الوضع الداكن هو المنشور حالياً).
class C {
  static const orange = Color(0xFFC93D05);
  static const bg = Color(0xFF171313);
  static const card = Color(0xFF1C1B1B);
  static const field = Color(0xFF373333);
  static const muted = Color(0xFF686464);
  static const line = Color(0xFFDADADA);
  static const gold = Color(0xFFFFDD67);
}

ThemeData matbkhyTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(primary: C.orange, surface: C.card, onPrimary: Colors.white),
    textTheme: base.textTheme.apply(fontFamily: 'Tajawal', bodyColor: Colors.white, displayColor: Colors.white),
    appBarTheme: const AppBarTheme(
      backgroundColor: C.bg, elevation: 0, centerTitle: true,
      titleTextStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.orange, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: C.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    ),
  );
}
