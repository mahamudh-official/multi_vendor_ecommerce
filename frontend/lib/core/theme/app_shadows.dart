import 'package:flutter/material.dart';

/// Elevation shadow definitions.
///
/// Provides subtle, consistent box shadows for elevated surfaces.
abstract final class AppShadows {
  AppShadows._();

  // ── Light theme shadows ────────────────────────────────────────────────
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  // ── Dark theme shadows (more subtle) ──────────────────────────────────
  static const List<BoxShadow> smDark = [
    BoxShadow(color: Color(0x28000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> mdDark = [
    BoxShadow(color: Color(0x3D000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> lgDark = [
    BoxShadow(color: Color(0x4D000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
}
