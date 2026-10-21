import 'package:equatable/equatable.dart';
import 'package:tandea/core/usecases/usecase.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/domain/entities/unirse_tanda_result.dart';
import 'package:tandea/features/tandas/domain/repositories/tandas_repository.dart';

/// Parámetros para unirse a una tanda activa.
class JoinTandaParams extends Equatable {
  final String inviteCode;
  final int? selectedNumber;

  const JoinTandaParams({
    required this.inviteCode,
    this.selectedNumber,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'inviteCode': inviteCode.trim().toUpperCase(),
      if (selectedNumber != null) 'selectedNumber': selectedNumber,
    };
  }

  @override
  List<Object?> get props => [inviteCode, selectedNumber];
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
