import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/entities/unirse_tanda_result.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';
import 'package:tandea/features/tandas/domain/usecases/unirse_tanda_usecase.dart';

const _tanda = TandaEntity(
  id: '1',
  nombre: 'Tanda',
  monto: 100,
  totalParticipantes: 3,
  periodo: 'quincenal',
  estado: 'PENDIENTE',
);

/// Repositorio de tandas vacío para pruebas que solo navegan.
class TandasRepositoryFake implements TandasRepository {
  int llamadasMisTandas = 0;

  @override
  Future<Result<List<TandaEntity>>> getTandas() async => const Success([]);
  @override
  Future<Result<List<TandaEntity>>> getMisTandas({required String rol}) async {
    llamadasMisTandas++;
    return const Success([]);
  }
  @override
  Future<Result<TandaEntity>> getTandaById(String id) async => const Success(_tanda);
  @override
  Future<Result<TandaEntity>> createTanda(Map<String, dynamic> tandaData) async => const Success(_tanda);
  @override
  Future<Result<TandaEntity>> getTandaByInviteCode(String inviteCode) async => const Success(_tanda);
  @override
  Future<Result<TandaEntity>> iniciarTanda(String id) async => const Success(_tanda);
  @override
  Future<Result<UnirseTandaResult>> joinTanda(JoinTandaParams params) async =>
      const Success(UnirseTandaResult(tanda: _tanda, numeroAsignado: 1));
}
