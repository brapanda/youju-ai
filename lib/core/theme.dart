import 'package:flutter/material.dart';

const mint = Color(0xFF0ECD87);
const forest = Color(0xFF087B56);

ThemeData youjuTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: mint, brightness: brightness).copyWith(
    primary: dark ? mint : forest,
    onPrimary: dark ? const Color(0xFF062B20) : Colors.white,
    surface: dark ? const Color(0xFF17251F) : const Color(0xFFFFFFFF),
    onSurface: dark ? const Color(0xFFF0F5F1) : const Color(0xFF172B24),
    onSurfaceVariant: dark ? const Color(0xFFA2B5AB) : const Color(0xFF6B7B72),
    outlineVariant: dark ? const Color(0xFF2D4036) : const Color(0xFFE5EAE4),
  );
  return ThemeData(
    useMaterial3: true, brightness: brightness, colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF0C1712) : const Color(0xFFF6F7F2),
    fontFamily: 'NotoSansSC',
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
      fontFamily: 'NotoSansSC',
      bodyColor: scheme.onSurface, displayColor: scheme.onSurface,
    ),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: scheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    dividerColor: scheme.outlineVariant,
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: scheme.surface, showDragHandle: true),
    chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), side: BorderSide(color: scheme.outlineVariant)),
  );
}

extension YoujuColors on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
