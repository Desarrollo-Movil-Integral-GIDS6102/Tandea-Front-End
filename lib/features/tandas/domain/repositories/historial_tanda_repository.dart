import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/domain/entities/movimiento_historial.dart';

/// Historial de pagos y cobros de una tanda (AP-09).
abstract class HistorialTandaRepository {
  /// Una página del historial, del movimiento más reciente al más antiguo.
  /// [cursor] es el `nextCursor` de la página anterior (null para la primera).
  Future<Result<PaginaHistorial>> getHistorial(String idTanda, {String? cursor, int limit = 20});
}
