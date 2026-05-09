import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const ColorScheme lightColorScheme = ColorScheme.light(
  primary: Color(0xFF456C62),
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFBCE6D9),
  onPrimaryContainer: Color(0xFF2F554C),
  primaryFixed: Color(0xFFBCE6D9),
  primaryFixedDim: Color(0xFFAED7CC),
  onPrimaryFixed: Color(0xFF1B423A),
  onPrimaryFixedVariant: Color(0xFF385F56),
  secondary: Color(0xFF915700),
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFFFFDCBC),
  onSecondaryContainer: Color(0xFF774600),
  secondaryFixed: Color(0xFFFFDCBC),
  secondaryFixedDim: Color(0xFFFFCB96),
  tertiary: Color(0xFF7D600D),
  onTertiary: Colors.white,
  tertiaryContainer: Color(0xFFF9D377),
  onTertiaryContainer: Color(0xFF5F4800),
  surface: Color(0xFFFEFDF1),
  onSurface: Color(0xFF353A26),
  surfaceDim: Color(0xFFE0E6C5),
  surfaceBright: Color(0xFFFEFDF1),
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: Color(0xFFFAFAEB),
  surfaceContainer: Color(0xFFF4F5E2),
  surfaceContainerHigh: Color(0xFFEDF0D8),
  surfaceContainerHighest: Color(0xFFE7EBCF),
  onSurfaceVariant: Color(0xFF626750),
  outline: Color(0xFF7E836B),
  outlineVariant: Color(0xFFB7BCA2),
  error: Color(0xFFB33938),
  onError: Colors.white,
  errorContainer: Color(0xFFF56965),
);

const ColorScheme darkColorScheme = ColorScheme.dark(
  primary: Color(0xFFA0D0C2),
  onPrimary: Color(0xFF0B3027),
  primaryContainer: Color(0xFF2D4F46),
  onPrimaryContainer: Color(0xFFBCE6D9),
  primaryFixed: Color(0xFFBCE6D9),
  primaryFixedDim: Color(0xFFAED7CC),
  onPrimaryFixed: Color(0xFF1B423A),
  onPrimaryFixedVariant: Color(0xFF385F56),
  secondary: Color(0xFFFFB778),
  onSecondary: Color(0xFF4D2D00),
  secondaryContainer: Color(0xFF6B4000),
  onSecondaryContainer: Color(0xFFFFDCBC),
  secondaryFixed: Color(0xFFFFDCBC),
  secondaryFixedDim: Color(0xFFFFCB96),
  tertiary: Color(0xFFE8C76C),
  onTertiary: Color(0xFF3F3000),
  tertiaryContainer: Color(0xFF5C4500),
  onTertiaryContainer: Color(0xFFF9D377),
  surface: Color(0xFF161A0E),
  onSurface: Color(0xFFE7EBCF),
  surfaceDim: Color(0xFF161A0E),
  surfaceBright: Color(0xFF383C2E),
  surfaceContainerLowest: Color(0xFF0F130A),
  surfaceContainerLow: Color(0xFF1E2214),
  surfaceContainer: Color(0xFF232719),
  surfaceContainerHigh: Color(0xFF2E3322),
  surfaceContainerHighest: Color(0xFF393E2D),
  onSurfaceVariant: Color(0xFFB7BCA2),
  outline: Color(0xFF818674),
  outlineVariant: Color(0xFF444838),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690004),
  errorContainer: Color(0xFF93000A),
);

ThemeData buildAppTheme(ColorScheme colorScheme) {
  final textTheme = GoogleFonts.plusJakartaSansTextTheme(
    colorScheme.brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme,
  ).copyWith(
    displayLarge: GoogleFonts.plusJakartaSans(
      fontSize: 56,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.5,
      height: 1.05,
      color: colorScheme.onSurface,
    ),
    displayMedium: GoogleFonts.plusJakartaSans(
      fontSize: 45,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      height: 1.1,
      color: colorScheme.onSurface,
    ),
    displaySmall: GoogleFonts.plusJakartaSans(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.15,
      color: colorScheme.onSurface,
    ),
    headlineLarge: GoogleFonts.plusJakartaSans(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.2,
      color: colorScheme.onSurface,
    ),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.25,
      color: colorScheme.onSurface,
    ),
    headlineSmall: GoogleFonts.plusJakartaSans(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.3,
      color: colorScheme.onSurface,
    ),
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.3,
      color: colorScheme.onSurface,
    ),
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.4,
      color: colorScheme.onSurface,
    ),
    titleSmall: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.4,
      color: colorScheme.onSurface,
    ),
    bodyLarge: GoogleFonts.workSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.55,
      color: colorScheme.onSurface,
    ),
    bodyMedium: GoogleFonts.workSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: colorScheme.onSurface,
    ),
    bodySmall: GoogleFonts.workSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: colorScheme.onSurfaceVariant,
    ),
    labelLarge: GoogleFonts.workSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      height: 1.4,
      color: colorScheme.onSurface,
    ),
    labelMedium: GoogleFonts.workSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      height: 1.4,
      color: colorScheme.onSurfaceVariant,
    ),
    labelSmall: GoogleFonts.workSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      height: 1.4,
      color: colorScheme.onSurfaceVariant,
    ),
  );

  return ThemeData(
    colorScheme: colorScheme,
    textTheme: textTheme,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.surface,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.6),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return GoogleFonts.workSans(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: colorScheme.onSurface,
        );
      }),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelStyle: GoogleFonts.workSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      hintStyle: GoogleFonts.workSans(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.workSans(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.workSans(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
  );
}
