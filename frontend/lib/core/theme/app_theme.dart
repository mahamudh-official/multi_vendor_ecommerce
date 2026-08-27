import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// Material 3 theme factory.
///
/// Provides light and dark [ThemeData] instances using the design system tokens.
/// All color, typography, and shape tokens are centralized in the theme files.
abstract final class AppTheme {
  AppTheme._();

  // ────────────────────────────────────────────────────────────────────────────
  // LIGHT THEME
  // ────────────────────────────────────────────────────────────────────────────
  static ThemeData get light {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColorsLight.primary,
      onPrimary: AppColorsLight.onPrimary,
      primaryContainer: AppColorsLight.primaryVariant,
      onPrimaryContainer: AppColorsLight.onPrimary,
      secondary: AppColorsLight.accent,
      onSecondary: AppColorsLight.onAccent,
      secondaryContainer: Color(0xFFD6E4FF),
      onSecondaryContainer: AppColorsLight.accent,
      tertiary: AppColorsLight.accentBright,
      onTertiary: AppColorsLight.onAccent,
      tertiaryContainer: Color(0xFFE9D5FF),
      onTertiaryContainer: AppColorsLight.accentBright,
      error: AppColorsLight.error,
      onError: AppColorsLight.onError,
      errorContainer: Color(0xFFFFE4E4),
      onErrorContainer: AppColorsLight.error,
      surface: AppColorsLight.surface,
      onSurface: AppColorsLight.onSurface,
      onSurfaceVariant: AppColorsLight.onSurfaceVariant,
      outline: AppColorsLight.outline,
      outlineVariant: AppColorsLight.outlineVariant,
      shadow: Color(0x1F000000),
      scrim: Color(0x52000000),
      inverseSurface: AppColorsLight.neutral800,
      onInverseSurface: AppColorsLight.neutral50,
      inversePrimary: Color(0xFF7C9EE7),
      surfaceTint: AppColorsLight.primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColorsLight.background,

      // ── AppBar ─────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsLight.surface,
        foregroundColor: AppColorsLight.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColorsLight.onSurface,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // ── Typography ─────────────────────────────────────────────────────
      textTheme: _buildTextTheme(AppColorsLight.onSurface, AppColorsLight.onSurfaceVariant),

      // ── Card ───────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColorsLight.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: AppColorsLight.outline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated Button ────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsLight.primary,
          foregroundColor: AppColorsLight.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTextStyles.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Outlined Button ────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsLight.primary,
          side: BorderSide(color: AppColorsLight.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTextStyles.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Text Button ────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsLight.accent,
          textStyle: AppTextStyles.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),

      // ── Input Decoration ───────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsLight.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.textField),
          borderSide: BorderSide(color: AppColorsLight.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.textField),
          borderSide: BorderSide(color: AppColorsLight.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.textField),
          borderSide: BorderSide(color: AppColorsLight.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.textField),
          borderSide: BorderSide(color: AppColorsLight.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColorsLight.onSurfaceVariant),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColorsLight.onSurfaceVariant),
      ),

      // ── Chip ───────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColorsLight.surfaceVariant,
        selectedColor: AppColorsLight.primary,
        labelStyle: AppTextStyles.labelMedium.copyWith(color: AppColorsLight.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          side: BorderSide(color: AppColorsLight.outline),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // ── Bottom Navigation ──────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorsLight.surface,
        selectedItemColor: AppColorsLight.primary,
        unselectedItemColor: AppColorsLight.onSurfaceVariant,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),

      // ── Navigation Bar (Material 3) ────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColorsLight.surface,
        indicatorColor: AppColorsLight.primary.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColorsLight.primary, size: 24);
          }
          return IconThemeData(color: AppColorsLight.onSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(color: AppColorsLight.primary);
          }
          return AppTextStyles.labelSmall.copyWith(color: AppColorsLight.onSurfaceVariant);
        }),
        elevation: 0,
        height: 72,
      ),

      // ── Divider ────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: AppColorsLight.outline,
        thickness: 1,
        space: 0,
      ),

      // ── Icon ───────────────────────────────────────────────────────────
      iconTheme: IconThemeData(
        color: AppColorsLight.onSurface,
        size: 24,
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // DARK THEME
  // ────────────────────────────────────────────────────────────────────────────
  static ThemeData get dark {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColorsDark.primary,
      onPrimary: AppColorsDark.onPrimary,
      primaryContainer: AppColorsDark.primaryVariant,
      onPrimaryContainer: AppColorsDark.onPrimary,
      secondary: AppColorsDark.accent,
      onSecondary: AppColorsDark.onAccent,
      secondaryContainer: Color(0xFF1E3A6E),
      onSecondaryContainer: AppColorsDark.accent,
      tertiary: AppColorsDark.accentBright,
      onTertiary: AppColorsDark.onAccent,
      tertiaryContainer: Color(0xFF3B1F5E),
      onTertiaryContainer: AppColorsDark.accentBright,
      error: AppColorsDark.error,
      onError: AppColorsDark.onError,
      errorContainer: Color(0xFF4A1515),
      onErrorContainer: AppColorsDark.error,
      surface: AppColorsDark.surface,
      onSurface: AppColorsDark.onSurface,
      onSurfaceVariant: AppColorsDark.onSurfaceVariant,
      outline: AppColorsDark.outline,
      outlineVariant: AppColorsDark.outlineVariant,
      shadow: Color(0x3D000000),
      scrim: Color(0x7A000000),
      inverseSurface: AppColorsDark.neutral800,
      onInverseSurface: AppColorsDark.neutral50,
      inversePrimary: AppColorsLight.primary,
      surfaceTint: AppColorsDark.accent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColorsDark.background,

      // ── AppBar ─────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsDark.surface,
        foregroundColor: AppColorsDark.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColorsDark.onSurface,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // ── Typography ─────────────────────────────────────────────────────
      textTheme: _buildTextTheme(AppColorsDark.onSurface, AppColorsDark.onSurfaceVariant),

      // ── Card ───────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColorsDark.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: AppColorsDark.outline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated Button ────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
          foregroundColor: AppColorsDark.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTextStyles.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Outlined Button ────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.primary,
          side: BorderSide(color: AppColorsDark.outline, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTextStyles.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Text Button ────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsDark.accent,
          textStyle: AppTextStyles.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),

      // ── Input Decoration ───────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.textField),
          borderSide: BorderSide(color: AppColorsDark.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.textField),
          borderSide: BorderSide(color: AppColorsDark.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.textField),
          borderSide: BorderSide(color: AppColorsDark.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.textField),
          borderSide: BorderSide(color: AppColorsDark.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColorsDark.onSurfaceVariant),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColorsDark.onSurfaceVariant),
      ),

      // ── Chip ───────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColorsDark.surfaceVariant,
        selectedColor: AppColorsDark.accent,
        labelStyle: AppTextStyles.labelMedium.copyWith(color: AppColorsDark.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          side: BorderSide(color: AppColorsDark.outline),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // ── Bottom Navigation ──────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorsDark.surface,
        selectedItemColor: AppColorsDark.primary,
        unselectedItemColor: AppColorsDark.onSurfaceVariant,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),

      // ── Navigation Bar (Material 3) ────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColorsDark.surface,
        indicatorColor: AppColorsDark.accent.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColorsDark.primary, size: 24);
          }
          return IconThemeData(color: AppColorsDark.onSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(color: AppColorsDark.primary);
          }
          return AppTextStyles.labelSmall.copyWith(color: AppColorsDark.onSurfaceVariant);
        }),
        elevation: 0,
        height: 72,
      ),

      // ── Divider ────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: AppColorsDark.outline,
        thickness: 1,
        space: 0,
      ),

      // ── Icon ───────────────────────────────────────────────────────────
      iconTheme: IconThemeData(
        color: AppColorsDark.onSurface,
        size: 24,
      ),
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: primary),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: primary),
      displaySmall: AppTextStyles.displaySmall.copyWith(color: primary),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: primary),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: primary),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(color: primary),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: primary),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: primary),
      titleSmall: AppTextStyles.titleSmall.copyWith(color: primary),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primary),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: secondary),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: secondary),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: primary),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: secondary),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: secondary),
    );
  }
}
