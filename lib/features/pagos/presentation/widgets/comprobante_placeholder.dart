import 'package:flutter/material.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';

/// Espacio para el comprobante del pago.
///
/// TODO: SP-2-[FE-PAGO] Agregar captura/subida de foto de comprobante
/// (image_picker, compresión y vista previa). Al elegir el archivo, llamar a
/// [onComprobanteSeleccionado] con un [ComprobanteArchivo] (bytes, nombre y mimeType).
class ComprobantePlaceholder extends StatelessWidget {
  final bool requerido;
  final ComprobanteArchivo? comprobante;
  final ValueChanged<ComprobanteArchivo?> onComprobanteSeleccionado;

  const ComprobantePlaceholder({
    super.key,
    required this.requerido,
    required this.onComprobanteSeleccionado,
    this.comprobante,
  });

  @override
  Widget build(BuildContext context) {
    final archivo = comprobante;

    return Container(
      key: const Key('comprobante_placeholder'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            archivo == null ? Icons.receipt_long_outlined : Icons.check_circle_outline,
            color: archivo == null ? AppColors.textDisabled : AppColors.success,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requerido ? 'Comprobante (obligatorio)' : 'Comprobante (opcional)',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  archivo?.nombre ?? 'JPG, PNG o PDF de hasta 10 MB. Pronto podrás adjuntarlo aquí.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
