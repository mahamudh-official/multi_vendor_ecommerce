/// Corner radius design tokens.
abstract final class AppRadius {
  AppRadius._();

  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xl2 = 24.0;
  static const double full = 999.0;

  // ── Semantic aliases ───────────────────────────────────────────────────
  static const double button = md;         // 12
  static const double card = lg;           // 16
  static const double chip = full;         // pill
  static const double textField = sm;      // 8
  static const double modal = xl;          // 20
  static const double productCard = lg;    // 16
  static const double avatar = full;       // circle
  static const double badge = full;        // pill
}
