import 'package:tandea/features/admin/domain/entities/admin_metricas_entity.dart';

class ConteoUsuariosModel extends ConteoUsuarios {
  const ConteoUsuariosModel({
    required super.total,
    required super.activos,
    required super.suspendidos,
  });

  factory ConteoUsuariosModel.fromJson(Map<String, dynamic> json) {
    return ConteoUsuariosModel(
      total: (json['total'] as num?)?.toInt() ?? 0,
      activos: (json['activos'] as num?)?.toInt() ?? 0,
      suspendidos: (json['suspendidos'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'activos': activos,
        'suspendidos': suspendidos,
      };
}

class ConteoTandasModel extends ConteoTandas {
  const ConteoTandasModel({
    required super.total,
    required super.pendientes,
    required super.activas,
    required super.finalizadas,
    required super.suspendidas,
    super.canceladas,
  });

  factory ConteoTandasModel.fromJson(Map<String, dynamic> json) {
    return ConteoTandasModel(
      total: (json['total'] as num?)?.toInt() ?? 0,
      pendientes: (json['pendientes'] as num?)?.toInt() ?? 0,
      activas: (json['activas'] as num?)?.toInt() ?? 0,
      finalizadas: (json['finalizadas'] as num?)?.toInt() ?? 0,
      suspendidas: (json['suspendidas'] as num?)?.toInt() ?? 0,
      canceladas: (json['canceladas'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'pendientes': pendientes,
        'activas': activas,
        'finalizadas': finalizadas,
        'suspendidas': suspendidas,
        'canceladas': canceladas,
      };
}

class MontoMensualModel extends MontoMensual {
  const MontoMensualModel({
    required super.mes,
    required super.monto,
    required super.pagos,
  });

  factory MontoMensualModel.fromJson(Map<String, dynamic> json) {
    final rawMonto = json['monto'];
    final monto = rawMonto is num
        ? rawMonto.toDouble()
        : double.tryParse(rawMonto?.toString() ?? '') ?? 0.0;

    return MontoMensualModel(
      mes: (json['mes'] ?? '').toString(),
      monto: monto,
      pagos: (json['pagos'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'mes': mes,
        'monto': monto,
        'pagos': pagos,
      };
}

/// Modelo DTO para serializar/deserializar la respuesta de `GET /api/v1/admin/metricas`.
class AdminMetricasModel extends AdminMetricasEntity {
  const AdminMetricasModel({
    required super.usuarios,
    required super.tandas,
    required super.montoGestionado,
    required super.disputasPendientes,
    required super.montoPorMes,
  });

  factory AdminMetricasModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final usuariosMap = payload['usuarios'] is Map<String, dynamic>
        ? payload['usuarios'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final tandasMap = payload['tandas'] is Map<String, dynamic>
        ? payload['tandas'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final rawMonto = payload['montoGestionado'];
    final montoGestionado = rawMonto is num
        ? rawMonto.toDouble()
        : double.tryParse(rawMonto?.toString() ?? '') ?? 0.0;

    final listaMeses = payload['montoPorMes'];
    final montoPorMes = listaMeses is List
        ? listaMeses
            .whereType<Map<String, dynamic>>()
            .map(MontoMensualModel.fromJson)
            .toList()
        : const <MontoMensualModel>[];

    return AdminMetricasModel(
      usuarios: ConteoUsuariosModel.fromJson(usuariosMap),
      tandas: ConteoTandasModel.fromJson(tandasMap),
      montoGestionado: montoGestionado,
      disputasPendientes: (payload['disputasPendientes'] as num?)?.toInt() ?? 0,
      montoPorMes: montoPorMes,
    );
  }

  AdminMetricasEntity toEntity() => this;
}
