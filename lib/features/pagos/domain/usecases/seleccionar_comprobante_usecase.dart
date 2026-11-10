import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';
import 'package:tandea/features/pagos/domain/entities/origen_imagen.dart';
import 'package:tandea/features/pagos/domain/services/comprobante_service.dart';

/// Caso de uso para obtener un comprobante de pago comprimido desde cámara o galería.
class SeleccionarComprobanteUseCase {
  final ComprobanteService comprobanteService;

  SeleccionarComprobanteUseCase({required this.comprobanteService});

  Future<Result<ComprobanteArchivo?>> call(OrigenImagen origen) {
    return comprobanteService.obtenerComprobante(origen);
  }
}
