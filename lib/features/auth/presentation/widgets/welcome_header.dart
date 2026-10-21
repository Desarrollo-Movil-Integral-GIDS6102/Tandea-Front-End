import 'package:flutter/material.dart';
import 'package:tandea/core/constants/app_colors.dart';

/// Sección superior de la pantalla de bienvenida.
///
/// Muestra:
/// - Fondo con degradado vertical de 0F766E (AppColors.primaryDark) a 0D9488 (AppColors.primary).
/// - Círculo blanco con ícono de Material (Icons.groups_rounded).
/// - Nombre "Tandea" en blanco, grande y en negrita.
/// - Eslogan "En términos de tandear, ¿Tandeas?" en blanco.
class WelcomeHeader extends StatelessWidget {
  final double? height;

  const WelcomeHeader({
    super.key,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Círculo blanco con ícono de Material
              // TODO: Reemplazar el ícono por el logo oficial de Tandea cuando exista el asset.
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  size: 46,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 20),

              // Nombre de la aplicación (texto grande y negrita para alto contraste accesible)
              const Text(
                'Tandea',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Eslogan de la aplicación
              const Text(
                'En términos de tandear, ¿Tandeas?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
