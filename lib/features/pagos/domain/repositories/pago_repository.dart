import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';

/// Contrato abstracto del repositorio de pagos en la capa de dominio.
abstract class PagoRepository {
  Future<Result<List<PagoEntity>>> getPagosByTanda(String tandaId);

  Future<Result<PagoEntity>> registrarPago({
    required String tandaId,
    required double monto,
    String? comprobanteUrl,
  });
}
