import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Visual password strength meter providing real-time visual feedback.
class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.password});

  final String password;

  int get _score {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score.clamp(0, 4);
  }

  String get _label => switch (_score) {
    0 => '',
    1 => 'Weak',
    2 => 'Fair',
    3 => 'Good',
    4 => 'Strong',
    _ => '',
  };

  Color _color(bool isDark) => switch (_score) {
    0 => Colors.transparent,
    1 => isDark ? AppColorsDark.error : AppColorsLight.error,
    2 => isDark ? AppColorsDark.warning : AppColorsLight.warning,
    3 => isDark ? AppColorsDark.info : AppColorsLight.info,
    4 => isDark ? AppColorsDark.success : AppColorsLight.success,
    _ => Colors.transparent,
  };

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = _color(isDark);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (index) {
              final isActive = index < _score;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: isActive
                        ? activeColor
                        : (isDark
                              ? AppColorsDark.outline
                              : AppColorsLight.outline),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            'Strength: $_label',
            style: AppTextStyles.bodySmall.copyWith(
              color: activeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
