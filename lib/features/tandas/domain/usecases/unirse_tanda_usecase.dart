import 'package:equatable/equatable.dart';
import 'package:tandea/core/usecases/usecase.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/domain/entities/unirse_tanda_result.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';

/// Parámetros para unirse a una tanda activa.
class JoinTandaParams extends Equatable {
  final String inviteCode;
  final List<int> selectedNumbers;

  /// Solo sorteo: cuántos números asignar al azar y si deben ser seguidos.
  final int? cantidad;
  final bool? consecutivos;

  const JoinTandaParams({
    required this.inviteCode,
    this.selectedNumbers = const [],
    this.cantidad,
    this.consecutivos,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'inviteCode': inviteCode.trim().toUpperCase(),
      if (selectedNumbers.isNotEmpty) 'selectedNumbers': selectedNumbers,
      if (cantidad != null) 'cantidad': cantidad,
      if (consecutivos != null) 'consecutivos': consecutivos,
    };
  }

  @override
  List<Object?> get props => [inviteCode, selectedNumbers, cantidad, consecutivos];
}

/// Caso de uso para unirse a una tanda en el backend (POST /tandas/unirse).
class UnirseTandaUseCase implements UseCase<UnirseTandaResult, JoinTandaParams> {
  final TandasRepository repository;

  UnirseTandaUseCase({required this.repository});

  @override
  Future<Result<UnirseTandaResult>> call(JoinTandaParams params) {
    return repository.joinTanda(params);
  }
}
