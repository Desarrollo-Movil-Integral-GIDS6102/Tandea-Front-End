import 'package:equatable/equatable.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';

/// Resultado devuelto tras unirse exitosamente a una tanda.
class UnirseTandaResult extends Equatable {
  final TandaEntity tanda;
  final int numeroAsignado;
  final List<int> numerosAsignados;

  /// Solo sorteo: si los números asignados forman un bloque seguido.
  final bool? consecutivos;
  final bool isDeadNumber;
  final String mensaje;

  const UnirseTandaResult({
    required this.tanda,
    required this.numeroAsignado,
    this.numerosAsignados = const [],
    this.consecutivos,
    this.isDeadNumber = false,
    this.mensaje = 'Te has unido exitosamente a la tanda',
  });

  @override
  List<Object?> get props => [tanda, numeroAsignado, numerosAsignados, consecutivos, isDeadNumber, mensaje];
}
