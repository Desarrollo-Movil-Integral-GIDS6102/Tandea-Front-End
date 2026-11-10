import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/entregas/domain/entities/entrega_entity.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';

abstract class EntregaRepository {
  /// `POST /entregas` (multipart): el organizador registra el turno vigente.
  Future<Result<EntregaEntity>> registrar({
    required int idNumber,
    required double transferencia,
    required double efectivo,
    required ComprobanteArchivo evidencia,
  });

  Future<Result<EntregaEntity>> obtener(int idPayout);

  /// `PATCH /entregas/:id/confirmar`: quien cobra confirma y se cierra el turno.
  Future<Result<EntregaEntity>> confirmar(int idPayout);

  Future<Result<void>> reportarProblema(int idPayout, String motivo);
}
