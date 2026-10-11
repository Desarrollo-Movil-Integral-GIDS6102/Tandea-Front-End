import 'package:flutter/material.dart';
import 'package:tandea/core/constants/app_colors.dart';

/// Botón principal reutilizable del proyecto Tandea.
///
/// Cumple con las especificaciones de diseño y accesibilidad:
/// - Fondo: 0F766E (AppColors.primaryDark, garantiza alto contraste con blanco)
/// - Texto: Blanco (16sp, w600)
/// - Dimensiones por defecto: ancho completo, alto 52, radio 12
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double? width;
  final double borderRadius;
  final Widget? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height = 52.0,
    this.width,
    this.borderRadius = 12.0,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryDark.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : (icon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon!,
                      const SizedBox(width: 8),
                      Text(text),
                    ],
                  )
                : Text(text)),
      ),
    );
  }
}
