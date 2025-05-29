import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData appTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
      primary: Color(0xFFFF6949),
      secondary: const Color(0xFFFF6949),
      background: const Color(0xFFF7F7F7),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      surface: const Color(0xFFF7F7F7),
      onSurface: Color(0xFFFF6949),
      error: const Color(0xFFEF4444),
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F7F7),
    textTheme: GoogleFonts.interTextTheme()
        .apply(bodyColor: Colors.black, displayColor: Colors.black)
        .copyWith(
          headlineLarge: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFF6949),
          ),
          headlineMedium: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFF6949),
          ),
          bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.black),
          bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.black),
        ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFF6949), // Confirmed button color
        foregroundColor: const Color.fromARGB(255, 240, 240, 240),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 4,
        shadowColor: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.2),
      ).copyWith(animationDuration: const Duration(milliseconds: 200)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: const BorderSide(
          color: Color(0xFFE1E1E1),
        ), // Cancel button border
        backgroundColor: const Color(0xFFE1E1E1), // Cancel button color
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ).copyWith(animationDuration: const Duration(milliseconds: 200)),
    ),
    cardTheme: const CardTheme(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      margin: EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      shadowColor: Color(0xFFE5E7EB),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        borderSide: BorderSide(color: Color(0xFFFF6949), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
      ),
      labelStyle: TextStyle(color: Colors.black),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFFF6949), size: 24),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFF6949),
      foregroundColor: Colors.white,
      elevation: 4,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      shadowColor: Color(0xFFE5E7EB),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFF6949),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
    ),
  );
}
