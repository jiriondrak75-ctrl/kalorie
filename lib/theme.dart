import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Paleta převzatá z Nákupního seznamu (tmavá, ve stylu VS Code).
const bg = Color(0xFF28282B);
const surface = Color(0xFF111111);
const surfaceVariant = Color(0xFF1E1E1E);
const blue = Color(0xFF0E639C);
const blueLight = Color(0xFF1177BB);
const textColor = Color(0xFFD4D4D4);
const textDim = Color(0xFF858585);
const danger = Color(0xFFB71C1C); // Colors.red.shade900

const radius = 12.0;

/// Měřítko rozestupů podle šířky displeje (jako v Nákupním seznamu).
double uiScale(BuildContext context) => MediaQuery.sizeOf(context).width / 360;

ThemeData buildTheme() {
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      surface: surface,
      surfaceContainerHighest: surfaceVariant,
      primary: blue,
      onPrimary: Colors.white,
      secondary: blueLight,
      onSecondary: Colors.white,
      secondaryContainer: surfaceVariant,
      onSecondaryContainer: textColor,
      onSurface: textColor,
      outline: textDim,
      error: danger,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: surfaceVariant),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceVariant,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceVariant,
      contentTextStyle: GoogleFonts.nunito(color: textColor),
      actionTextColor: blueLight,
      behavior: SnackBarBehavior.floating,
      shape: rounded,
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: surfaceVariant,
      surfaceTintColor: Colors.transparent,
    ),
    dividerColor: surfaceVariant,
    listTileTheme: const ListTileThemeData(
      textColor: textColor,
      iconColor: textDim,
    ),
    textTheme: GoogleFonts.nunitoTextTheme(
      const TextTheme(
        bodyMedium: TextStyle(color: textColor),
        bodySmall: TextStyle(color: textDim),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: textDim),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        foregroundColor: textDim,
        selectedBackgroundColor: blue,
        selectedForegroundColor: Colors.white,
        side: const BorderSide(color: textDim),
        visualDensity: VisualDensity.compact,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: blueLight),
  );
}
