import 'package:flutter/material.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';

/// Componente de UI para captura, selección y vista previa de comprobantes de pago (AP-04).
class ComprobantePlaceholder extends StatelessWidget {
  final bool requerido;
  final ComprobanteArchivo? comprobante;
  final ValueChanged<ComprobanteArchivo?>? onComprobanteSeleccionado;
  final bool procesando;
  final VoidCallback? onTomarFoto;
  final VoidCallback? onSeleccionarGaleria;
  final VoidCallback? onEliminar;

  const ComprobantePlaceholder({
    super.key,
    required this.requerido,
    this.comprobante,
    this.onComprobanteSeleccionado,
    this.procesando = false,
    this.onTomarFoto,
    this.onSeleccionarGaleria,
    this.onEliminar,
  });

  void _mostrarOpciones(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Adjuntar comprobante',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  key: const Key('opcion_modal_camara'),
                  leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                  title: const Text('Tomar foto con la cámara'),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    onTomarFoto?.call();
                  },
                ),
                ListTile(
                  key: const Key('opcion_modal_galeria'),
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                  title: const Text('Elegir de la galería'),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    onSeleccionarGaleria?.call();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarVistaCompleta(BuildContext context, ComprobanteArchivo archivo) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  child: Image.memory(
                    archivo.bytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.black.withValues(alpha: 0.6),
                ),
                icon: const Icon(Icons.close, color: AppColors.surface),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final archivo = comprobante;

    // 1. Estado de carga / compresión
    if (procesando) {
      return Container(
        key: const Key('comprobante_placeholder'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
        ),
        child: const Column(
          children: [
            SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(
                key: Key('comprobante_cargando'),
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Procesando y optimizando imagen...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // 2. Estado con comprobante seleccionado (Vista previa)
    if (archivo != null) {
      final tamanoKb = (archivo.bytes.length / 1024).toStringAsFixed(1);

      return Container(
        key: const Key('comprobante_placeholder'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    archivo.nombre,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$tamanoKb KB',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _mostrarVistaCompleta(context, archivo),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.memory(
                      archivo.bytes,
                      key: const Key('preview_comprobante'),
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          color: AppColors.background,
                          alignment: Alignment.center,
                          child: const Text(
                            'Vista previa no disponible',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                    Container(
                      height: 160,
                      color: AppColors.black.withValues(alpha: 0.15),
                      alignment: Alignment.bottomRight,
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: AppColors.surface, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Ampliar',
                              style: TextStyle(color: AppColors.surface, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('boton_cambiar_comprobante'),
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('Cambiar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _mostrarOpciones(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('boton_eliminar_comprobante'),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onEliminar,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 3. Estado sin comprobante
    return Container(
      key: const Key('comprobante_placeholder'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.textDisabled,
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
                    const Text(
                      'Toma una foto o selecciona una imagen de tu galería (JPG o PNG de hasta 10 MB).',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('boton_camara'),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Cámara'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onTomarFoto,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('boton_galeria'),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Galería'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onSeleccionarGaleria,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
