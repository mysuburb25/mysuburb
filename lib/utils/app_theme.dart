import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colours — warm eucalyptus green anchored by red-earth terracotta
  static const Color brandGreen = Color(0xFF2D6A4F);
  static const Color brandGreenLight = Color(0xFF52B788);
  static const Color brandGreenPale = Color(0xFFD8F3DC);
  static const Color terracotta = Color(0xFFBC4749);
  static const Color sand = Color(0xFFF8F4EF);
  static const Color charcoal = Color(0xFF1B1F23);
  static const Color midGrey = Color(0xFF6B7280);
  static const Color lightGrey = Color(0xFFE5E7EB);
  static const Color white = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: brandGreen,
        onPrimary: white,
        secondary: brandGreenLight,
        onSecondary: white,
        error: terracotta,
        onError: white,
        surface: white,
        onSurface: charcoal,
      ),
      scaffoldBackgroundColor: sand,
      fontFamily: 'SF Pro Display',
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: charcoal,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: charcoal,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: brandGreen,
        unselectedItemColor: midGrey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandGreen,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandGreen,
          side: const BorderSide(color: brandGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: terracotta),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: midGrey, fontSize: 15),
        labelStyle: const TextStyle(color: midGrey, fontSize: 15),
      ),
      cardTheme: CardTheme(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: brandGreenPale,
        labelStyle: const TextStyle(color: brandGreen, fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }
}

class AppConstants {
  static const String appName = 'My Suburb';
  static const String appTagline = 'Your neighbourhood, connected.';

  static const List<String> australianStates = [
    'Australian Capital Territory',
    'New South Wales',
    'Northern Territory',
    'Queensland',
    'South Australia',
    'Tasmania',
    'Victoria',
    'Western Australia',
  ];

  static const List<String> postCategories = [
    'General',
    'Community Notice',
    'Event',
    'Lost & Found',
    'Marketplace',
    'Safety Alert',
  ];

  static const List<String> marketplaceCategories = [
    'All',
    'Electronics',
    'Furniture',
    'Clothing',
    'Garden',
    'Kids & Baby',
    'Sports',
    'Tools',
    'Vehicles',
    'Free',
    'Other',
  ];

  static const List<String> eventCategories = [
    'Markets',
    'Sports',
    'Community Meeting',
    'Fundraiser',
    'Social',
    'Kids',
    'Other',
  ];

  static const int feedPageSize = 20;
}
