import 'package:tandea/core/usecases/usecase.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';

/// Caso de uso para consultar información de una tanda por su código de invitación (GET /tandas/codigo/:inviteCode).
class ObtenerTandaPorCodigoUseCase implements UseCase<TandaEntity, String> {
  final TandasRepository repository;

  ObtenerTandaPorCodigoUseCase({required this.repository});

  @override
  Future<Result<TandaEntity>> call(String inviteCode) {
    return repository.getTandaByInviteCode(inviteCode.trim().toUpperCase());
  }
}
