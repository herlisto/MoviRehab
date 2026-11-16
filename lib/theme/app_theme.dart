import 'package:flutter/material.dart';

/// Tema visual «naturaleza» de MoviRehab: verdes de bosque y musgo, tierra
/// cálida como acento y fondos crema (claro) o verde muy oscuro (oscuro).
class AppTheme {
  const AppTheme._();

  static const ColorScheme _esquemaClaro = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2E6B4F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFCDEBD6),
    onPrimaryContainer: Color(0xFF0B2E1D),
    secondary: Color(0xFF56793C),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDDEBC8),
    onSecondaryContainer: Color(0xFF1C2E0B),
    tertiary: Color(0xFF8F5A2A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF4DEC4),
    onTertiaryContainer: Color(0xFF3A2108),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF5F8EF),
    onSurface: Color(0xFF1B2A21),
    onSurfaceVariant: Color(0xFF45594C),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFEFF4E8),
    surfaceContainer: Color(0xFFE9F0E1),
    surfaceContainerHigh: Color(0xFFE2EBD8),
    surfaceContainerHighest: Color(0xFFDBE5D0),
    outline: Color(0xFF74897B),
    outlineVariant: Color(0xFFC2D1C5),
    inverseSurface: Color(0xFF2F3E35),
    onInverseSurface: Color(0xFFEAF3EA),
    inversePrimary: Color(0xFF8FD3A8),
  );

  static const ColorScheme _esquemaOscuro = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8FD3A8),
    onPrimary: Color(0xFF00391F),
    primaryContainer: Color(0xFF1F5139),
    onPrimaryContainer: Color(0xFFB0F0C6),
    secondary: Color(0xFFB4D18F),
    onSecondary: Color(0xFF213611),
    secondaryContainer: Color(0xFF384D26),
    onSecondaryContainer: Color(0xFFD0EDAA),
    tertiary: Color(0xFFEBBE8B),
    onTertiary: Color(0xFF442A0B),
    tertiaryContainer: Color(0xFF5E3F1F),
    onTertiaryContainer: Color(0xFFFFDDBA),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF0F1B15),
    onSurface: Color(0xFFDFE9E0),
    onSurfaceVariant: Color(0xFFB4C7B9),
    surfaceContainerLowest: Color(0xFF0A130E),
    surfaceContainerLow: Color(0xFF14221B),
    surfaceContainer: Color(0xFF182A21),
    surfaceContainerHigh: Color(0xFF21342A),
    surfaceContainerHighest: Color(0xFF2B4034),
    outline: Color(0xFF819588),
    outlineVariant: Color(0xFF3A4E42),
    inverseSurface: Color(0xFFDFE9E0),
    onInverseSurface: Color(0xFF26352C),
    inversePrimary: Color(0xFF2E6B4F),
  );

  static final ThemeData claro = _construir(_esquemaClaro);
  static final ThemeData oscuro = _construir(_esquemaOscuro);

  static ThemeData _construir(ColorScheme esquema) {
    const radioTarjeta = 24.0;
    final bordeCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: esquema.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: esquema.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: esquema.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: esquema.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: esquema.surfaceContainerLowest.withValues(
          alpha: esquema.brightness == Brightness.light ? 0.92 : 0.55,
        ),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioTarjeta),
          side: BorderSide(color: esquema.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: esquema.primary,
          foregroundColor: esquema.onPrimary,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: esquema.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: const StadiumBorder()),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: esquema.primary,
        foregroundColor: esquema.onPrimary,
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquema.surfaceContainerLow,
        border: bordeCampo,
        enabledBorder: bordeCampo,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: esquema.primary, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: esquema.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: esquema.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        iconColor: esquema.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: esquema.inverseSurface,
        contentTextStyle: TextStyle(color: esquema.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: esquema.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: esquema.primaryContainer,
          selectedForegroundColor: esquema.onPrimaryContainer,
        ),
      ),
    );
  }
}
