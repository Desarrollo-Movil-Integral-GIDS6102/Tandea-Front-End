import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/domain/entities/seguimiento_tanda.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/entities/unirse_tanda_result.dart';
import 'package:tandea/features/tandas/domain/usecases/unirse_tanda_usecase.dart';

/// Contrato abstracto del repositorio de tandas en la capa de dominio.
abstract class TandasRepository {
  Future<Result<List<TandaEntity>>> getTandas();
  Future<Result<List<TandaEntity>>> getMisTandas({required String rol});
  Future<Result<TandaEntity>> getTandaById(String id);
  Future<Result<TandaEntity>> createTanda(Map<String, dynamic> tandaData);
  Future<Result<TandaEntity>> getTandaByInviteCode(String inviteCode);
  Future<Result<UnirseTandaResult>> joinTanda(JoinTandaParams params);

  /// Estado de pago de cada turno en la vuelta actual (`GET /tandas/:id/seguimiento`).
  Future<Result<SeguimientoTanda>> getSeguimiento(String idTanda);

  /// Pasa la tanda de PENDIENTE a ACTIVA (solo organizador).
  Future<Result<TandaEntity>> iniciarTanda(String id);
}


