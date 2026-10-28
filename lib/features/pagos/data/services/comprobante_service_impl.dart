import 'package:image_picker/image_picker.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/pagos/data/services/image_compressor_service.dart';
import 'package:tandea/features/pagos/data/services/permission_service.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';
import 'package:tandea/features/pagos/domain/entities/origen_imagen.dart';
import 'package:tandea/features/pagos/domain/services/comprobante_service.dart';

/// Implementación concreta de [ComprobanteService] en la capa de datos.
class ComprobanteServiceImpl implements ComprobanteService {
  final ImagePicker imagePicker;
  final ImageCompressorService compressorService;
  final PermissionService permissionService;

  /// Tamaño máximo permitido para comprobantes: 10 MB.
  static const int tamanoMaximoBytes = 10 * 1024 * 1024;

  ComprobanteServiceImpl({
    required this.imagePicker,
    required this.compressorService,
    required this.permissionService,
  });

  @override
  Future<Result<ComprobanteArchivo?>> obtenerComprobante(OrigenImagen origen) async {
    try {
      // 1. Verificación y solicitud de permisos
      if (origen == OrigenImagen.camara) {
        final permiso = await permissionService.solicitarPermisoCamara();
        if (!permiso) {
          return const Error(
            PermissionFailure(
              'No se concedió permiso para usar la cámara. Habilítalo en los ajustes del dispositivo.',
            ),
          );
        }
      } else {
        final permiso = await permissionService.solicitarPermisoGaleria();
        if (!permiso) {
          return const Error(
            PermissionFailure(
              'No se concedió permiso para acceder a la galería. Habilítalo en los ajustes del dispositivo.',
            ),
          );
        }
      }

      // 2. Selección o captura de la imagen con image_picker
      final source = origen == OrigenImagen.camara ? ImageSource.camera : ImageSource.gallery;
      final XFile? file = await imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      // Cancelación por parte del usuario: no es un error
      if (file == null) {
        return const Success(null);
      }

      final rawBytes = await file.readAsBytes();
      if (rawBytes.isEmpty) {
        return const Error(ValidationFailure('La imagen seleccionada está vacía o no es válida.'));
      }

      // 3. Optimización y compresión con flutter_image_compress
      final compressedBytes = await compressorService.comprimir(
        rawBytes,
        calidad: 80,
        minWidth: 1280,
        minHeight: 1280,
      );

      if (compressedBytes.length > tamanoMaximoBytes) {
        return const Error(
          ValidationFailure('El comprobante supera el tamaño máximo permitido de 10 MB.'),
        );
      }

      final nombreOriginal = file.name.isNotEmpty
          ? file.name
          : 'comprobante_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final nombreFinal = (nombreOriginal.toLowerCase().endsWith('.jpg') ||
              nombreOriginal.toLowerCase().endsWith('.jpeg'))
          ? nombreOriginal
          : '$nombreOriginal.jpg';

      return Success(
        ComprobanteArchivo(
          bytes: compressedBytes,
          nombre: nombreFinal,
          mimeType: 'image/jpeg',
        ),
      );
    } catch (e) {
      return Error(MediaFailure('Error al procesar el comprobante: $e'));
    }
  }
}
