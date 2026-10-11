import 'package:equatable/equatable.dart';

/// Entidad pura del dominio que representa una tanda de ahorro rotativo.
class TandaEntity extends Equatable {
  final String id;
  final String nombre;
  final double monto;
  final int totalParticipantes;
  final String periodo;
  final String estado;

  const TandaEntity({
    required this.id,
    required this.nombre,
    required this.monto,
    required this.totalParticipantes,
    required this.periodo,
    required this.estado,
  });

  @override
  List<Object?> get props => [id, nombre, monto, totalParticipantes, periodo, estado];
}
