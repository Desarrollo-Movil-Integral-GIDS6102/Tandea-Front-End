import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';

/// Modelo DTO para la serialización y deserialización de tandas.
class TandaModel extends TandaEntity {
  const TandaModel({
    required super.id,
    required super.nombre,
    required super.monto,
    required super.totalParticipantes,
    required super.periodo,
    required super.estado,
  });

  factory TandaModel.fromJson(Map<String, dynamic> json) {
    return TandaModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      nombre: (json['nombre'] ?? json['name'] ?? '').toString(),
      monto: ((json['monto'] ?? json['amount'] ?? 0) as num).toDouble(),
      totalParticipantes: ((json['totalParticipantes'] ?? json['participantesCount'] ?? 0) as num).toInt(),
      periodo: (json['periodo'] ?? json['period'] ?? 'quincenal').toString(),
      estado: (json['estado'] ?? json['status'] ?? 'activa').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'monto': monto,
      'totalParticipantes': totalParticipantes,
      'periodo': periodo,
      'estado': estado,
    };
  }

  TandaEntity toEntity() => this;
}
