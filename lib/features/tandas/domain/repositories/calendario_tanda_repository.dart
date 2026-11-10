import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/domain/entities/calendario_tanda.dart';

/// Repositorio para consultar el calendario de turnos de una tanda (`GET /tandas/:id/calendario`, AP-06).
abstract class CalendarioTandaRepository {
  Future<Result<CalendarioTanda>> getCalendario(String idTanda);
}

