import 'package:tandea/features/pagos/domain/entities/metodo_pago.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';

/// Modelo DTO para la serialización y deserialización de pagos
/// (respuesta de `POST /api/v1/pagos`).
class PagoModel extends PagoEntity {
  const PagoModel({
    required super.idPayment,
    required super.idNumber,
    required super.metodoPago,
    required super.transferAmount,
    required super.cashAmount,
    required super.totalAmount,
    required super.status,
    super.confirmedByParticipant,
    super.confirmedByAdmin,
    super.ocrVerified,
    super.ocrDetectedAmount,
    super.evidenceUrl,
    super.createdAt,
  });

  static double _toDouble(dynamic raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic raw) {
    if (raw is num) {
      return raw.toInt();
    }
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  factory PagoModel.fromJson(Map<String, dynamic> json) {
    final ocrDetectedAmount = json['ocrDetectedAmount'];
    final createdAt = json['createdAt'];

    return PagoModel(
      idPayment: _toInt(json['idPayment'] ?? json['id']),
      idNumber: _toInt(json['idNumber']),
      metodoPago: MetodoPago.fromValor(json['metodoPago']?.toString()),
      transferAmount: _toDouble(json['transferAmount']),
      cashAmount: _toDouble(json['cashAmount']),
      totalAmount: _toDouble(json['totalAmount']),
      status: (json['status'] ?? 'PENDIENTE').toString(),
      confirmedByParticipant: json['confirmedByParticipant'] == true,
      confirmedByAdmin: json['confirmedByAdmin'] == true,
      ocrVerified: json['ocrVerified'] == true,
      ocrDetectedAmount: ocrDetectedAmount == null ? null : _toDouble(ocrDetectedAmount),
      evidenceUrl: json['evidenceUrl'] as String?,
      createdAt: createdAt == null ? null : DateTime.tryParse(createdAt.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'idPayment': idPayment,
      'idNumber': idNumber,
      'metodoPago': metodoPago.valor,
      'transferAmount': transferAmount,
      'cashAmount': cashAmount,
      'totalAmount': totalAmount,
      'status': status,
      'confirmedByParticipant': confirmedByParticipant,
      'confirmedByAdmin': confirmedByAdmin,
      'ocrVerified': ocrVerified,
      'ocrDetectedAmount': ocrDetectedAmount,
      'evidenceUrl': evidenceUrl,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  PagoEntity toEntity() => this;
}
