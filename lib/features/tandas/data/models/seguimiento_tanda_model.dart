import 'package:tandea/features/tandas/domain/entities/seguimiento_tanda.dart';

/// DTO de `GET /tandas/:id/seguimiento`.
///
/// Tolera camelCase y snake_case, y el estado tanto como `estadoPago`
/// (`PAGADO`/`PENDIENTE`/`ATRASADO`) o como el `status` del pago.
class SeguimientoTandaModel extends SeguimientoTanda {
  const SeguimientoTandaModel({
    required super.idTanda,
    required super.nombreTanda,
    required super.vueltaActual,
    required super.cuota,
    required super.participantes,
    super.totalVueltas,
  });

  static double _toDouble(dynamic raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static int? _toIntOrNull(dynamic raw) {
    if (raw is num) {
      return raw.toInt();
    }
    return int.tryParse(raw?.toString() ?? '');
  }

  static ParticipanteSeguimiento participanteFromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] ?? json['user'];
    final pago = json['pago'] ?? json['payment'];
    final pagoMap = pago is Map<String, dynamic> ? pago : const <String, dynamic>{};
    final isDeadNumber = (json['isDeadNumber'] ?? json['is_dead_number']) == true;

    String? nombre = (json['nombre'] ?? json['nombreParticipante'] ?? json['name'])?.toString();
    if ((nombre == null || nombre.isEmpty) && usuario is Map<String, dynamic>) {
      nombre = [usuario['name'] ?? usuario['nombre'], usuario['lastName'] ?? usuario['apellido']]
          .where((parte) => parte != null && parte.toString().isNotEmpty)
          .join(' ');
    }
    if (nombre == null || nombre.isEmpty) {
      nombre = isDeadNumber ? 'Número muerto' : 'Sin asignar';
    }

    final rawEstado = json['estadoPago'] ??
        json['estado_pago'] ??
        json['estado'] ??
        pagoMap['status'];
    final atrasado = json['atrasado'] == true || json['enMora'] == true;
    final fecha = json['fechaPago'] ?? json['fecha_pago'] ?? pagoMap['createdAt'];

    return ParticipanteSeguimiento(
      idNumber: _toIntOrNull(json['idNumber'] ?? json['id_number']) ?? 0,
      numeroTurno: _toIntOrNull(json['numeroTurno'] ?? json['numberValue'] ?? json['number_value']) ?? 0,
      nombre: nombre,
      isDeadNumber: isDeadNumber,
      idPayment: _toIntOrNull(json['idPayment'] ?? json['id_payment'] ?? pagoMap['idPayment']),
      estadoPago: atrasado ? EstadoPagoSeguimiento.atrasado : EstadoPagoSeguimiento.fromValor(rawEstado?.toString()),
      montoPagado: _toDouble(json['montoPagado'] ?? pagoMap['totalAmount']),
      fechaPago: fecha == null ? null : DateTime.tryParse(fecha.toString()),
    );
  }

  factory SeguimientoTandaModel.fromJson(Map<String, dynamic> json) {
    final tanda = json['tanda'] is Map<String, dynamic> ? json['tanda'] as Map<String, dynamic> : json;
    final rawLista = json['participantes'] ?? json['numeros'] ?? json['numbers'];
    final participantes = (rawLista is List<dynamic> ? rawLista : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(participanteFromJson)
        .toList()
      ..sort((a, b) => a.numeroTurno.compareTo(b.numeroTurno));

    return SeguimientoTandaModel(
      idTanda: (tanda['idTanda'] ?? tanda['id'] ?? '').toString(),
      nombreTanda: (tanda['nombre'] ?? tanda['name'] ?? '').toString(),
      vueltaActual: _toIntOrNull(json['vueltaActual'] ?? json['roundNumber'] ?? json['round_number']) ?? 1,
      totalVueltas: _toIntOrNull(json['totalVueltas'] ?? tanda['numRounds'] ?? tanda['num_rounds']),
      cuota: _toDouble(json['cuota'] ?? tanda['contributionAmount'] ?? tanda['contribution_amount']),
      participantes: participantes,
    );
  }
}
