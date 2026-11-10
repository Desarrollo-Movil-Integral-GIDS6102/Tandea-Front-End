import 'package:tandea/core/usecases/usecase.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/domain/entities/seguimiento_tanda.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';

/// Caso de uso para consultar quién pagó y quién no en la vuelta actual (GET /tandas/:id/seguimiento).
class ObtenerSeguimientoTandaUseCase implements UseCase<SeguimientoTanda, String> {
  final TandasRepository repository;

  ObtenerSeguimientoTandaUseCase({required this.repository});

  @override
  Future<Result<SeguimientoTanda>> call(String idTanda) {
    return repository.getSeguimiento(idTanda);
  }
}
