import 'package:equatable/equatable.dart';

/// Estado de pago de un participante en la vuelta actual de la tanda.
enum EstadoPagoSeguimiento {
  /// Pago confirmado (`CONFIRMADO` en el backend).
  pagado,

  /// Aún no paga o su pago espera confirmación, dentro del plazo.
  pendiente,

  /// No ha pagado y ya venció el plazo (fecha límite + días de gracia).
  atrasado;

  /// Acepta tanto el estado del panel (`PAGADO`, `PENDIENTE`, `ATRASADO`)
  /// como el del pago (`CONFIRMADO`, `RECHAZADO`). Cualquier otro valor es pendiente.
  static EstadoPagoSeguimiento fromValor(String? valor) {
    switch (valor?.trim().toUpperCase()) {
      case 'PAGADO':
      case 'CONFIRMADO':
        return EstadoPagoSeguimiento.pagado;
      case 'ATRASADO':
      case 'VENCIDO':
      case 'MORA':
        return EstadoPagoSeguimiento.atrasado;
      default:
        return EstadoPagoSeguimiento.pendiente;
    }
  }

  String get etiqueta => switch (this) {
        EstadoPagoSeguimiento.pagado => 'Pagado',
        EstadoPagoSeguimiento.pendiente => 'Pendiente',
        EstadoPagoSeguimiento.atrasado => 'Atrasado',
      };
}

/// Un turno (`number`) de la vuelta actual con su estado de pago.
class ParticipanteSeguimiento extends Equatable {
  final int idNumber;

  /// Número visible del turno (`number_value`).
  final int numeroTurno;
  final String nombre;
  final bool isDeadNumber;
  final EstadoPagoSeguimiento estadoPago;

  /// Monto pagado en la vuelta; 0 si no hay pago.
  final double montoPagado;
  final DateTime? fechaPago;

  const ParticipanteSeguimiento({
    required this.idNumber,
    required this.numeroTurno,
    required this.nombre,
    required this.estadoPago,
    this.isDeadNumber = false,
    this.montoPagado = 0,
    this.fechaPago,
  });

  @override
  List<Object?> get props => [
        idNumber,
        numeroTurno,
        nombre,
        isDeadNumber,
        estadoPago,
        montoPagado,
        fechaPago,
      ];
}

/// Respuesta de `GET /tandas/:id/seguimiento`: quién pagó y quién no en la vuelta actual.
class SeguimientoTanda extends Equatable {
  final String idTanda;
  final String nombreTanda;
  final int vueltaActual;
  final int? totalVueltas;
  final double cuota;
  final List<ParticipanteSeguimiento> participantes;

  const SeguimientoTanda({
    required this.idTanda,
    required this.nombreTanda,
    required this.vueltaActual,
    required this.cuota,
    required this.participantes,
    this.totalVueltas,
  });

  int contar(EstadoPagoSeguimiento estado) =>
      participantes.where((p) => p.estadoPago == estado).length;

  int get totalPagados => contar(EstadoPagoSeguimiento.pagado);

  /// Fracción (0..1) de pagos confirmados sobre el total de turnos de la vuelta.
  double get progreso => participantes.isEmpty ? 0 : totalPagados / participantes.length;

  @override
  List<Object?> get props => [
        idTanda,
        nombreTanda,
        vueltaActual,
        totalVueltas,
        cuota,
        participantes,
      ];
}
