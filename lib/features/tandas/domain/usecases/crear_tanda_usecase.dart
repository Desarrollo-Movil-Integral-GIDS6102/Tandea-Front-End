import 'package:equatable/equatable.dart';
import 'package:tandea/core/usecases/usecase.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';

/// Parámetros validados para el caso de uso de creación de tanda en backend.
class CrearTandaParams extends Equatable {
  final String name;
  final String? description;
  final String startDate; // Formato YYYY-MM-DD
  final double contributionAmount;
  final int numParticipants;
  final int numRounds;
  final int graceDays;
  final bool hasDeadNumber;
  final int idTandaType;

  const CrearTandaParams({
    required this.name,
    this.description,
    required this.startDate,
    required this.contributionAmount,
    required this.numParticipants,
    this.numRounds = 1,
    this.graceDays = 0,
    this.hasDeadNumber = false,
    this.idTandaType = 1,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name.trim(),
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      'startDate': startDate,
      'contributionAmount': contributionAmount,
      'numParticipants': numParticipants,
      'numRounds': numRounds,
      'graceDays': graceDays,
      'hasDeadNumber': hasDeadNumber,
      'idTandaType': idTandaType,
    };
  }

  @override
  List<Object?> get props => [
        name,
        description,
        startDate,
        contributionAmount,
        numParticipants,
        numRounds,
        graceDays,
        hasDeadNumber,
        idTandaType,
      ];
}

/// Caso de uso para enviar la creación de una tanda al endpoint POST /tandas.
class CrearTandaUseCase implements UseCase<TandaEntity, CrearTandaParams> {
  final TandasRepository repository;

  CrearTandaUseCase({required this.repository});

  @override
  Future<Result<TandaEntity>> call(CrearTandaParams params) {
    return repository.createTanda(params.toJson());
  }
}
