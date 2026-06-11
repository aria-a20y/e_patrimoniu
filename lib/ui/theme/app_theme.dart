import 'package:flutter/material.dart';

class AppTheme {
  // === CULORI PRINCIPALE e-Patrimoniu ===
  static const Color greenDark    = Color(0xFF1B4332);  // verde închis
  static const Color greenEmerald = Color(0xFF2D6A4F);  // verde smarald
  static const Color greenMid     = Color(0xFF40916C);  // verde mediu
  static const Color greenLight   = Color(0xFF52B788);  // verde deschis
  static const Color greenPale    = Color(0xFFD8F3DC);  // verde palid
  static const Color bgWhite      = Color(0xFFF8FFFE);  // alb cu tentă verde
  static const Color bgGrey       = Color(0xFFF1F5F4);  // gri deschis
  static const Color cardWhite    = Colors.white;
  static const Color textDark     = Color(0xFF1A2E1E);
  static const Color textGrey     = Color(0xFF6B7280);
  static const Color textLight    = Colors.white;
  static const Color borderColor  = Color(0xFFE5E7EB);
  static const Color errorRed     = Color(0xFFDC2626);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color infoBlue     = Color(0xFF2563EB);

  // Gradient principal
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [greenDark, greenEmerald, greenMid],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [greenDark, greenEmerald],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient loginGradient = LinearGradient(
    colors: [Color(0xFF081C15), Color(0xFF1B4332), Color(0xFF2D6A4F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);
  static bool get isDarkMode => themeMode.value == ThemeMode.dark;
  static void setDarkMode(bool isDark) {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        primaryColor: greenEmerald,
        scaffoldBackgroundColor: bgGrey,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: greenDark,
          foregroundColor: textLight,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textLight,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: greenEmerald,
            foregroundColor: textLight,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: greenEmerald, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: errorRed),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(color: textGrey, fontFamily: 'Inter'),
          hintStyle: const TextStyle(color: textGrey, fontFamily: 'Inter'),
        ),
        cardTheme: CardThemeData(
          color: cardWhite,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        colorScheme: const ColorScheme.light(
          primary: greenEmerald,
          secondary: greenLight,
          surface: bgWhite,
          error: errorRed,
          onPrimary: textLight,
          onSecondary: textLight,
          onSurface: textDark,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 28),
          headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 22),
          headlineSmall: TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 18),
          titleLarge: TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 16),
          titleMedium: TextStyle(fontWeight: FontWeight.w500, color: textDark, fontSize: 14),
          bodyLarge: TextStyle(color: textDark, fontSize: 15),
          bodyMedium: TextStyle(color: textDark, fontSize: 14),
          bodySmall: TextStyle(color: textGrey, fontSize: 12),
          labelLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        dividerTheme: const DividerThemeData(color: borderColor, thickness: 1),
        chipTheme: ChipThemeData(
          backgroundColor: greenPale,
          labelStyle: const TextStyle(color: greenDark, fontSize: 12, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
      );
}
