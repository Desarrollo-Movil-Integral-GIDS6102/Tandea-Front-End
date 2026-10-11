import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';

/// Modelo DTO para la serialización y deserialización de pagos.
class PagoModel extends PagoEntity {
  const PagoModel({
    required super.id,
    required super.tandaId,
    required super.usuarioId,
    required super.monto,
    required super.fecha,
    required super.estado,
    super.comprobanteUrl,
  });

  factory PagoModel.fromJson(Map<String, dynamic> json) {
    return PagoModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      tandaId: (json['tandaId'] ?? json['tanda_id'] ?? '').toString(),
      usuarioId: (json['usuarioId'] ?? json['user_id'] ?? '').toString(),
      monto: ((json['monto'] ?? json['amount'] ?? 0) as num).toDouble(),
      fecha: json['fecha'] != null
          ? DateTime.tryParse(json['fecha'].toString()) ?? DateTime.now()
          : DateTime.now(),
      estado: (json['estado'] ?? json['status'] ?? 'pendiente').toString(),
      comprobanteUrl: json['comprobanteUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'tandaId': tandaId,
      'usuarioId': usuarioId,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'estado': estado,
      if (comprobanteUrl != null) 'comprobanteUrl': comprobanteUrl,
    };
  }

  PagoEntity toEntity() => this;
}
