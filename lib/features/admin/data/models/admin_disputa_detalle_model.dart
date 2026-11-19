import 'package:tandea/features/admin/data/models/admin_disputa_model.dart';
import 'package:tandea/features/admin/domain/entities/admin_disputa_detalle_entity.dart';
import 'package:tandea/features/entregas/domain/entities/entrega_entity.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';

class BitacoraEntradaModel extends BitacoraEntradaEntity {
  const BitacoraEntradaModel({
    required super.idLog,
    super.idUser,
    required super.actionType,
    required super.entityType,
    super.entityId,
    required super.description,
    super.createdAt,
  });

  static int _toInt(dynamic raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  factory BitacoraEntradaModel.fromJson(Map<String, dynamic> json) {
    final rawCreated = json['createdAt'];
    return BitacoraEntradaModel(
      idLog: _toInt(json['idLog'] ?? json['id']),
      idUser: _toNullableInt(json['idUser']),
      actionType: (json['actionType'] ?? 'AUDIT').toString(),
      entityType: (json['entityType'] ?? 'DISPUTE').toString(),
      entityId: _toNullableInt(json['entityId']),
      description: (json['description'] ?? '').toString(),
      createdAt: rawCreated != null
          ? DateTime.tryParse(rawCreated.toString())
          : null,
    );
  }
}

/// Modelo DTO para serializar/deserializar `GET /api/v1/admin/disputas/:id`
/// enriquecido con `PagoEntity` o `EntregaEntity`.
class AdminDisputaDetalleModel extends AdminDisputaDetalleEntity {
  const AdminDisputaDetalleModel({
    required super.disputa,
    super.bitacora,
    super.pago,
    super.entrega,
  });

  factory AdminDisputaDetalleModel.fromJson(
    Map<String, dynamic> json, {
    PagoEntity? pago,
    EntregaEntity? entrega,
  }) {
    final payload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final disputa = AdminDisputaModel.fromJson(payload);
    final rawBitacora = payload['bitacora'];
    final bitacora = rawBitacora is List
        ? rawBitacora
            .whereType<Map<String, dynamic>>()
            .map(BitacoraEntradaModel.fromJson)
            .toList()
        : const <BitacoraEntradaModel>[];

    return AdminDisputaDetalleModel(
      disputa: disputa,
      bitacora: bitacora,
      pago: pago,
      entrega: entrega,
    );
  }

  AdminDisputaDetalleEntity toEntity() => this;
}
