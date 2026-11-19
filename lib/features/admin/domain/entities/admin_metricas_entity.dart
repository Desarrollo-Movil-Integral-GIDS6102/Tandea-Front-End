import 'package:equatable/equatable.dart';

/// Conteo desglosado de usuarios de la plataforma.
class ConteoUsuarios extends Equatable {
  final int total;
  final int activos;
  final int suspendidos;

  const ConteoUsuarios({
    required this.total,
    required this.activos,
    required this.suspendidos,
  });

  @override
  List<Object?> get props => [total, activos, suspendidos];
}

/// Conteo desglosado de tandas por estado en la plataforma.
class ConteoTandas extends Equatable {
  final int total;
  final int pendientes;
  final int activas;
  final int finalizadas;
  final int suspendidas;
  final int canceladas;

  const ConteoTandas({
    required this.total,
    required this.pendientes,
    required this.activas,
    required this.finalizadas,
    required this.suspendidas,
    this.canceladas = 0,
  });

  @override
  List<Object?> get props => [
        total,
        pendientes,
        activas,
        finalizadas,
        suspendidas,
        canceladas,
      ];
}

/// Volumen mensual de pagos confirmados (`YYYY-MM`).
class MontoMensual extends Equatable {
  final String mes;
  final double monto;
  final int pagos;

  const MontoMensual({
    required this.mes,
    required this.monto,
    required this.pagos,
  });

  /// Etiqueta corta legible para el eje X de la gráfica (ej. `2026-11` -> `Nov`).
  String get etiquetaMes {
    const nombres = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final partes = mes.split('-');
    if (partes.length == 2) {
      final numMes = int.tryParse(partes[1]);
      if (numMes != null && numMes >= 1 && numMes <= 12) {
        return nombres[numMes - 1];
      }
    }
    return mes;
  }

  @override
  List<Object?> get props => [mes, monto, pagos];
}

/// Entidad pura del dominio con las métricas analíticas globales (AP-11).
class AdminMetricasEntity extends Equatable {
  final ConteoUsuarios usuarios;
  final ConteoTandas tandas;
  final double montoGestionado;
  final int disputasPendientes;
  final List<MontoMensual> montoPorMes;

  const AdminMetricasEntity({
    required this.usuarios,
    required this.tandas,
    required this.montoGestionado,
    required this.disputasPendientes,
    required this.montoPorMes,
  });

  @override
  List<Object?> get props => [
        usuarios,
        tandas,
        montoGestionado,
        disputasPendientes,
        montoPorMes,
      ];
}
