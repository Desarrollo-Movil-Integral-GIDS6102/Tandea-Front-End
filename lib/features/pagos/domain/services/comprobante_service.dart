import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';
import 'package:tandea/features/pagos/domain/entities/origen_imagen.dart';

/// Contrato de servicio en la capa de dominio para captura, selección
/// y preparación de comprobantes de pago.
abstract class ComprobanteService {
  /// Obtiene un comprobante desde [origen] (cámara o galería), solicita permisos
  /// si son necesarios y entrega la imagen comprimida y validada.
  ///
  /// Devuelve `Success(null)` si el usuario canceló la captura o selección sin error.
  Future<Result<ComprobanteArchivo?>> obtenerComprobante(OrigenImagen origen);
}
