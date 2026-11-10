import 'package:tandea/features/tandas/domain/entities/calendario_tanda.dart';

/// DTO de `GET /tandas/:id/calendario` (`data: { tanda, fechaInicioPagos, turnos }`).
class CalendarioTandaModel extends CalendarioTanda {
  const CalendarioTandaModel({
    required super.idTanda,
    required super.fechaInicioPagos,
    required super.turnos,
  });

  static int _toInt(dynamic raw, {int fallback = 0}) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  static double _toDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static TurnoCalendario turnoFromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'];
    final usuarioMap = usuario is Map<String, dynamic> ? usuario : null;

    return TurnoCalendario(
      turno: _toInt(json['turno'], fallback: 1),
      vuelta: _toInt(json['vuelta'] ?? json['roundNumber'], fallback: 1),
      numero: _toInt(json['numero'] ?? json['numberValue']),
      esNumeroMuerto: (json['esNumeroMuerto'] ?? json['isDeadNumber']) == true,
      idUser: usuarioMap != null ? _toInt(usuarioMap['idUser']) : null,
      nombreUsuario: usuarioMap?['nombre']?.toString(),
      fechaCobro: (json['fechaCobro'] ?? json['fecha_cobro'] ?? '').toString(),
      montoAEsperar: _toDouble(json['montoAEsperar'] ?? json['monto_a_esperar']),
    );
  }

  factory CalendarioTandaModel.fromJson(Map<String, dynamic> json) {
    final tanda = json['tanda'] is Map<String, dynamic>
        ? json['tanda'] as Map<String, dynamic>
        : json;
    final rawTurnos = json['turnos'];

    return CalendarioTandaModel(
      idTanda: (tanda['idTanda'] ?? tanda['id'] ?? '').toString(),
      fechaInicioPagos: (json['fechaInicioPagos'] ?? tanda['startDate'] ?? '').toString(),
      turnos: (rawTurnos is List<dynamic> ? rawTurnos : const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(turnoFromJson)
          .toList(),
    );
  }
}

