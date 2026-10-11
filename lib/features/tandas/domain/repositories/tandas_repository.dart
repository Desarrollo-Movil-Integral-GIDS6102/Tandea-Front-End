import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';

/// Contrato abstracto del repositorio de tandas en la capa de dominio.
abstract class TandasRepository {
  Future<Result<List<TandaEntity>>> getTandas();
  Future<Result<TandaEntity>> getTandaById(String id);
  Future<Result<TandaEntity>> createTanda(Map<String, dynamic> tandaData);
}
