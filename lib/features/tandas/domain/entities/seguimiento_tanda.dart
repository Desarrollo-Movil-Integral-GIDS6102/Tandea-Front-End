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

  /// Pago registrado en la vuelta (para abrir "Revisar pago"); null si no hay.
  final int? idPayment;

  /// Monto pagado en la vuelta; 0 si no hay pago.
  final double montoPagado;
  final DateTime? fechaPago;

  const ParticipanteSeguimiento({
    required this.idNumber,
    required this.numeroTurno,
    required this.nombre,
    required this.estadoPago,
    this.isDeadNumber = false,
    this.idPayment,
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
        idPayment,
        montoPagado,
        fechaPago,
      ];
}

/// El turno que se está cobrando y cuánto se le entregaría hoy a su dueño (AP-10).
///
/// El backend descuenta del total del turno las cuotas que no están confirmadas.
class TurnoVigenteSeguimiento extends Equatable {
  final int idNumber;
  final int numeroTurno;

  /// `PENDIENTE`, `EN_RIESGO`, `ENTREGA_PENDIENTE_CONFIRMACION` o `ENTREGADO`.
  final String estadoTurno;

  /// Lo que se juntaría si todos hubieran pagado.
  final double totalTurno;

  /// Lo que se descuenta por las cuotas no confirmadas.
  final double descuento;

  /// Lo que realmente se entrega: es el monto que el backend exige al registrar la entrega.
  final double montoAEntregar;
  final int cuotasNoConfirmadas;

  /// true si la entrega no se puede registrar hasta regularizar los pagos que faltan.
  final bool bloqueado;

  const TurnoVigenteSeguimiento({
    required this.idNumber,
    required this.numeroTurno,
    required this.totalTurno,
    required this.montoAEntregar,
    this.estadoTurno = 'PENDIENTE',
    this.descuento = 0,
    this.cuotasNoConfirmadas = 0,
    this.bloqueado = false,
  });

  /// Mensaje para el organizador cuando la entrega no se puede registrar todavía; null si sí.
  String? get motivoBloqueo {
    if (bloqueado) {
      return 'El turno está en riesgo: faltan pagos por regularizar antes de registrar la entrega.';
    }
    if (montoAEntregar <= 0) {
      return 'Aún no hay pagos confirmados para entregar en este turno.';
    }
    return null;
  }

  @override
  List<Object?> get props => [
        idNumber,
        numeroTurno,
        estadoTurno,
        totalTurno,
        descuento,
        montoAEntregar,
        cuotasNoConfirmadas,
        bloqueado,
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

  /// null si ya se entregaron todos los turnos o si el backend no lo manda.
  final TurnoVigenteSeguimiento? turnoVigente;

  const SeguimientoTanda({
    required this.idTanda,
    required this.nombreTanda,
    required this.vueltaActual,
    required this.cuota,
    required this.participantes,
    this.totalVueltas,
    this.turnoVigente,
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
        turnoVigente,
      ];
}
