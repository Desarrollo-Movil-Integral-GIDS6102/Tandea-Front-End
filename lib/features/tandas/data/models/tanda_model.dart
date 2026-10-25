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
    super.inviteCode,
    super.startDate,
    super.graceDays,
    super.hasDeadNumber,
    super.idTandaType,
    super.indicadorPago,
    super.rolUsuario,
    super.idNumberUsuario,
    super.numeroTurnoUsuario,
  });

  static IndicadorPago _parseIndicadorPago(dynamic raw, String id, String status) {
    if (raw != null) {
      final s = raw.toString().toLowerCase();
      if (s.contains('pendiente') || s == 'pending' || s == 'unpaid') {
        return IndicadorPago.pendiente;
      }
      if (s.contains('dia') || s == 'paid' || s == 'aldia') {
        return IndicadorPago.alDia;
      }
    }
    // Mock mientras no exista el endpoint de pagos:
    if (status.toUpperCase() == 'FINALIZADA' || status.toUpperCase() == 'CANCELADA') {
      return IndicadorPago.alDia;
    }
    final seed = (id.isNotEmpty ? id.hashCode : 0).abs();
    return seed % 2 == 1 ? IndicadorPago.pendiente : IndicadorPago.alDia;
  }

  factory TandaModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['idTanda'] ?? json['_id'] ?? '').toString();
    final estado = (json['estado'] ?? json['status'] ?? 'activa').toString();
    final indicador = _parseIndicadorPago(
      json['indicadorPago'] ?? json['estadoPago'],
      id,
      estado,
    );
    final miNumero = json['miNumero'];

    return TandaModel(
      id: id,
      nombre: (json['nombre'] ?? json['name'] ?? '').toString(),
      monto: ((json['monto'] ?? json['contributionAmount'] ?? json['amount'] ?? 0) as num).toDouble(),
      totalParticipantes: ((json['totalParticipantes'] ?? json['numParticipants'] ?? json['participantesCount'] ?? 0) as num).toInt(),
      periodo: (json['periodo'] ?? json['period'] ?? 'quincenal').toString(),
      estado: estado,
      inviteCode: json['inviteCode']?.toString(),
      startDate: json['startDate']?.toString(),
      graceDays: (json['graceDays'] as num?)?.toInt(),
      hasDeadNumber: json['hasDeadNumber'] as bool?,
      idTandaType: (json['idTandaType'] as num?)?.toInt(),
      indicadorPago: indicador,
      rolUsuario: json['rolUsuario']?.toString(),
      idNumberUsuario: miNumero is Map ? (miNumero['idNumber'] as num?)?.toInt() : null,
      numeroTurnoUsuario: miNumero is Map ? (miNumero['numberValue'] as num?)?.toInt() : null,
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
      if (inviteCode != null) 'inviteCode': inviteCode,
      if (startDate != null) 'startDate': startDate,
      if (graceDays != null) 'graceDays': graceDays,
      if (hasDeadNumber != null) 'hasDeadNumber': hasDeadNumber,
      if (idTandaType != null) 'idTandaType': idTandaType,
    };
  }

  TandaEntity toEntity() => this;
}
