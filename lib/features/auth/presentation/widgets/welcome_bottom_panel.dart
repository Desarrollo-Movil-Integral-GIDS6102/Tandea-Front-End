import 'package:flutter/material.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/widgets/primary_button.dart';
import 'package:tandea/core/widgets/secondary_button.dart';
import 'package:tandea/features/auth/presentation/widgets/welcome_feature_chip.dart';

/// Panel inferior de la pantalla de bienvenida.
///
/// Contiene:
/// - Fondo F9FAFB con esquinas superiores redondeadas (radio 24).
/// - Título "Organiza tus tandas y alcanza tus metas" (111827).
/// - Línea de apoyo (4B5563).
/// - Tres chips de características clave:
///   "Pagos con evidencia", "Doble confirmación", "Recordatorios".
/// - Botón principal "Iniciar sesión" (0F766E, alto 52, radio 12).
/// - Botón secundario "Registrarse" (fondo blanco, borde 0D9488, texto 0F766E).
class WelcomeBottomPanel extends StatelessWidget {
  final VoidCallback onLoginPressed;
  final VoidCallback onRegisterPressed;

  const WelcomeBottomPanel({
    super.key,
    required this.onLoginPressed,
    required this.onRegisterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título del panel
          const Text(
            'Organiza tus tandas y alcanza tus metas',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Línea de apoyo
          const Text(
            'Ahorra en comunidad con total transparencia y control en cada ronda.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Chips de características
          const Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                WelcomeFeatureChip(
                  label: 'Pagos con evidencia',
                  icon: Icons.receipt_long_rounded,
                ),
                WelcomeFeatureChip(
                  label: 'Doble confirmación',
                  icon: Icons.verified_user_rounded,
                ),
                WelcomeFeatureChip(
                  label: 'Recordatorios',
                  icon: Icons.notifications_active_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Botón principal "Iniciar sesión"
          PrimaryButton(
            text: 'Iniciar sesión',
            onPressed: onLoginPressed,
          ),
          const SizedBox(height: 12),

          // Botón secundario "Registrarse"
          SecondaryButton(
            text: 'Registrarse',
            onPressed: onRegisterPressed,
          ),
        ],
      ),
    );
  }
}
