/// 8pt spacing grid constants.
///
/// All spacing values must reference these constants.
/// Avoids magic numbers scattered throughout the codebase.
abstract final class AppSpacing {
  AppSpacing._();

  // ── Base unit ──────────────────────────────────────────────────────────
  static const double unit = 4.0;

  // ── Named scale ───────────────────────────────────────────────────────
  static const double xs = unit; // 4
  static const double sm = unit * 2; // 8
  static const double md = unit * 3; // 12
  static const double lg = unit * 4; // 16
  static const double xl = unit * 5; // 20
  static const double xl2 = unit * 6; // 24
  static const double xl3 = unit * 8; // 32
  static const double xl4 = unit * 10; // 40
  static const double xl5 = unit * 12; // 48
  static const double xl6 = unit * 16; // 64
  static const double xl7 = unit * 20; // 80
  static const double xl8 = unit * 24; // 96

  // ── Page padding ──────────────────────────────────────────────────────
  static const double pagePaddingHorizontal = lg; // 16
  static const double pagePaddingVertical = xl2; // 24

  // ── Card padding ──────────────────────────────────────────────────────
  static const double cardPaddingH = lg; // 16
  static const double cardPaddingV = lg; // 16

  // ── Section gap ───────────────────────────────────────────────────────
  static const double sectionGap = xl3; // 32
  static const double itemGap = lg; // 16
  static const double tightGap = sm; // 8
}
