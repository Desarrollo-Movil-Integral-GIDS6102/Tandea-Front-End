import 'package:flutter/material.dart';
import 'package:tandea/core/constants/app_colors.dart';

/// Chip de característica para la pantalla de bienvenida.
///
/// Fondo: CCFBF1 (AppColors.primaryLight)
/// Texto: 0F766E (AppColors.primaryDark)
class WelcomeFeatureChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const WelcomeFeatureChip({
    super.key,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
