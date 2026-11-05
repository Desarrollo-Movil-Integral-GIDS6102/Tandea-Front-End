import 'package:equatable/equatable.dart';
import 'package:tandea/core/usecases/usecase.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/domain/entities/movimiento_historial.dart';
import 'package:tandea/features/tandas/domain/repositories/historial_tanda_repository.dart';

class HistorialParams extends Equatable {
  final String idTanda;
  final String? cursor;
  final int limit;

  const HistorialParams({required this.idTanda, this.cursor, this.limit = 20});

  @override
  List<Object?> get props => [idTanda, cursor, limit];
}

/// Caso de uso para consultar el historial de pagos y cobros (GET /tandas/:id/historial).
class ObtenerHistorialTandaUseCase implements UseCase<PaginaHistorial, HistorialParams> {
  final HistorialTandaRepository repository;

  ObtenerHistorialTandaUseCase({required this.repository});

  @override
  Future<Result<PaginaHistorial>> call(HistorialParams params) {
    return repository.getHistorial(params.idTanda, cursor: params.cursor, limit: params.limit);
  }
}
