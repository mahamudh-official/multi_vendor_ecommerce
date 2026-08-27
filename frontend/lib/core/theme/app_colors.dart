// Core application color tokens.
//
// All colors in the app must reference these constants.
// Never scatter raw Color values in widgets.
import 'package:flutter/material.dart';

/// Light theme color palette.
abstract final class AppColorsLight {
  // ── Primary brand ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A1A2E);
  static const Color primaryVariant = Color(0xFF16213E);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Accent / Action ────────────────────────────────────────────────────
  static const Color accent = Color(0xFF0F3460);
  static const Color accentBright = Color(0xFF533483);
  static const Color onAccent = Color(0xFFFFFFFF);

  // ── Surface ────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);
  static const Color surfaceContainer = Color(0xFFF1F3F5);
  static const Color onSurface = Color(0xFF1A1A2E);
  static const Color onSurfaceVariant = Color(0xFF6B7280);

  // ── Background ─────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8F9FA);
  static const Color onBackground = Color(0xFF1A1A2E);

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color error = Color(0xFFE53E3E);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF38A169);
  static const Color warning = Color(0xFFDD6B20);
  static const Color info = Color(0xFF3182CE);

  // ── Price / Commerce ───────────────────────────────────────────────────
  static const Color price = Color(0xFF0F3460);
  static const Color priceOriginal = Color(0xFF9CA3AF);
  static const Color badge = Color(0xFFE53E3E);
  static const Color onBadge = Color(0xFFFFFFFF);
  static const Color star = Color(0xFFF6AD55);

  // ── Outline ────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFFE5E7EB);
  static const Color outlineVariant = Color(0xFFD1D5DB);

  // ── Neutral scale ──────────────────────────────────────────────────────
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);
}

/// Dark theme color palette.
abstract final class AppColorsDark {
  // ── Primary brand ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFFE2E8F0);
  static const Color primaryVariant = Color(0xFFCBD5E0);
  static const Color onPrimary = Color(0xFF1A1A2E);

  // ── Accent / Action ────────────────────────────────────────────────────
  static const Color accent = Color(0xFF7C9EE7);
  static const Color accentBright = Color(0xFF9F7AEA);
  static const Color onAccent = Color(0xFF1A1A2E);

  // ── Surface ────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFF1E2030);
  static const Color surfaceVariant = Color(0xFF252840);
  static const Color surfaceContainer = Color(0xFF2D3050);
  static const Color onSurface = Color(0xFFE2E8F0);
  static const Color onSurfaceVariant = Color(0xFF94A3B8);

  // ── Background ─────────────────────────────────────────────────────────
  static const Color background = Color(0xFF151726);
  static const Color onBackground = Color(0xFFE2E8F0);

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color error = Color(0xFFFC8181);
  static const Color onError = Color(0xFF1A1A2E);
  static const Color success = Color(0xFF68D391);
  static const Color warning = Color(0xFFF6AD55);
  static const Color info = Color(0xFF63B3ED);

  // ── Price / Commerce ───────────────────────────────────────────────────
  static const Color price = Color(0xFF7C9EE7);
  static const Color priceOriginal = Color(0xFF64748B);
  static const Color badge = Color(0xFFFC8181);
  static const Color onBadge = Color(0xFF1A1A2E);
  static const Color star = Color(0xFFF6AD55);

  // ── Outline ────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF2D3050);
  static const Color outlineVariant = Color(0xFF374151);

  // ── Neutral scale ──────────────────────────────────────────────────────
  static const Color neutral50 = Color(0xFF1E2030);
  static const Color neutral100 = Color(0xFF252840);
  static const Color neutral200 = Color(0xFF2D3050);
  static const Color neutral300 = Color(0xFF374151);
  static const Color neutral400 = Color(0xFF4B5563);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral600 = Color(0xFF9CA3AF);
  static const Color neutral700 = Color(0xFFD1D5DB);
  static const Color neutral800 = Color(0xFFE5E7EB);
  static const Color neutral900 = Color(0xFFF3F4F6);
}
