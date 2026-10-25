import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';

/// Tamaño máximo que acepta el backend para el comprobante.
const int comprobanteMaxBytes = 10 * 1024 * 1024;

/// Abre la cámara o la galería y devuelve la foto comprimida (JPEG, máx. 1600 px),
/// o null si el usuario cancela. `image_picker` pide los permisos del sistema.
Future<ComprobanteArchivo?> seleccionarFotoComprobante(ImageSource origen) async {
  final foto = await ImagePicker().pickImage(
    source: origen,
    imageQuality: 70,
    maxWidth: 1600,
  );
  if (foto == null) {
    return null;
  }
  final bytes = await foto.readAsBytes();
  final esPng = bytes.length > 4 && bytes[0] == 0x89 && bytes[1] == 0x50;
  return ComprobanteArchivo(
    bytes: bytes,
    nombre: foto.name,
    mimeType: esPng ? 'image/png' : 'image/jpeg',
  );
}

/// Captura o elige la foto del comprobante y muestra la vista previa antes de enviar.
class ComprobanteSelector extends StatelessWidget {
  final bool requerido;
  final bool habilitado;
  final ComprobanteArchivo? comprobante;
  final ValueChanged<ComprobanteArchivo?> onComprobanteSeleccionado;

  /// Se puede reemplazar en pruebas para no abrir la cámara real.
  final Future<ComprobanteArchivo?> Function(ImageSource origen) seleccionarFoto;

  const ComprobanteSelector({
    super.key,
    required this.requerido,
    required this.onComprobanteSeleccionado,
    this.comprobante,
    this.habilitado = true,
    this.seleccionarFoto = seleccionarFotoComprobante,
  });

  Future<void> _elegir(BuildContext context, ImageSource origen) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final archivo = await seleccionarFoto(origen);
      if (archivo == null) {
        return;
      }
      if (archivo.bytes.length > comprobanteMaxBytes) {
        messenger.showSnackBar(
          const SnackBar(content: Text('La foto supera los 10 MB. Intenta con otra.')),
        );
        return;
      }
      onComprobanteSeleccionado(archivo);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No pudimos abrir la cámara o la galería. Revisa los permisos.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final archivo = comprobante;

    return Container(
      key: const Key('comprobante_selector'),
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
          Text(
            requerido ? 'Comprobante (obligatorio)' : 'Comprobante (opcional)',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (archivo == null)
            const Text(
              'Toma una foto o elige una imagen de tu galería (hasta 10 MB).',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    archivo.bytes,
                    key: const Key('comprobante_vista_previa'),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Text(archivo.nombre),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton.filledTonal(
                    key: const Key('comprobante_quitar'),
                    tooltip: 'Quitar comprobante',
                    icon: const Icon(Icons.close),
                    onPressed: habilitado ? () => onComprobanteSeleccionado(null) : null,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('comprobante_camara'),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Tomar foto'),
                  onPressed: habilitado ? () => _elegir(context, ImageSource.camera) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('comprobante_galeria'),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galería'),
                  onPressed: habilitado ? () => _elegir(context, ImageSource.gallery) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
