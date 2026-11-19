import 'package:tandea/features/admin/domain/entities/admin_disputa_entity.dart';

/// Modelo DTO para serializar/deserializar disputas en `/api/v1/admin/disputas`.
class AdminDisputaModel extends AdminDisputaEntity {
  const AdminDisputaModel({
    required super.idDispute,
    required super.idTanda,
    required super.nombreTanda,
    required super.idReporter,
    required super.nombreReporter,
    required super.emailReporter,
    super.idResolver,
    required super.reason,
    required super.status,
    super.resolutionNotes,
    super.idPayment,
    super.idPayout,
    super.createdAt,
    super.updatedAt,
    super.resolvedAt,
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

  static DateTime? _toDateTime(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  factory AdminDisputaModel.fromJson(Map<String, dynamic> json) {
    return AdminDisputaModel(
      idDispute: _toInt(json['idDispute'] ?? json['id']),
      idTanda: _toInt(json['idTanda']),
      nombreTanda: (json['nombreTanda'] ?? '').toString(),
      idReporter: _toInt(json['idReporter']),
      nombreReporter: (json['nombreReporter'] ?? '').toString(),
      emailReporter: (json['emailReporter'] ?? '').toString(),
      idResolver: _toNullableInt(json['idResolver']),
      reason: (json['reason'] ?? '').toString(),
      status: (json['status'] ?? 'ABIERTA').toString(),
      resolutionNotes: json['resolutionNotes']?.toString(),
      idPayment: _toNullableInt(json['idPayment']),
      idPayout: _toNullableInt(json['idPayout']),
      createdAt: _toDateTime(json['createdAt']),
      updatedAt: _toDateTime(json['updatedAt']),
      resolvedAt: _toDateTime(json['resolvedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'idDispute': idDispute,
        'idTanda': idTanda,
        'nombreTanda': nombreTanda,
        'idReporter': idReporter,
        'nombreReporter': nombreReporter,
        'emailReporter': emailReporter,
        'idResolver': idResolver,
        'reason': reason,
        'status': status,
        'resolutionNotes': resolutionNotes,
        'idPayment': idPayment,
        'idPayout': idPayout,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
      };

  AdminDisputaEntity toEntity() => this;
}
