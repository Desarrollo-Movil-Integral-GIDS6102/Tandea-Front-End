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

/// Estado del turno en el panel de seguimiento (AP-10):
///  - `alDia`: turno al corriente (`PENDIENTE`, `ENTREGA_PENDIENTE_CONFIRMACION`, `ENTREGADO`, `AL_DIA`).
///  - `enRiesgo`: faltan pagos tras la gracia y no hay número muerto disponible (`EN_RIESGO`).
///  - `cubierto`: la cuota vencida fue cubierta por el número muerto (`cubiertoPorNumeroMuerto: true` o `CUBIERTO`).
enum EstadoTurnoSeguimiento {
  alDia,
  enRiesgo,
  cubierto;

  static EstadoTurnoSeguimiento fromValores({
    String? estadoTurno,
    bool cubiertoPorNumeroMuerto = false,
  }) {
    if (cubiertoPorNumeroMuerto) {
      return EstadoTurnoSeguimiento.cubierto;
    }
    switch (estadoTurno?.trim().toUpperCase()) {
      case 'EN_RIESGO':
      case 'RIESGO':
        return EstadoTurnoSeguimiento.enRiesgo;
      case 'CUBIERTO':
      case 'CUBIERTO_POR_NUMERO_MUERTO':
        return EstadoTurnoSeguimiento.cubierto;
      default:
        return EstadoTurnoSeguimiento.alDia;
    }
  }

  String get etiqueta => switch (this) {
        EstadoTurnoSeguimiento.alDia => 'Al día',
        EstadoTurnoSeguimiento.enRiesgo => 'En riesgo',
        EstadoTurnoSeguimiento.cubierto => 'Cubierto',
      };
}

/// Un turno (`number`) de la vuelta actual con su estado de pago y estado de turno.
class ParticipanteSeguimiento extends Equatable {
  final int idNumber;

  /// Número visible del turno (`number_value`).
  final int numeroTurno;
  final String nombre;
  final bool isDeadNumber;
  final EstadoPagoSeguimiento estadoPago;

  /// Estado del turno en backend (`PENDIENTE`, `EN_RIESGO`, `ENTREGA_PENDIENTE_CONFIRMACION`, `ENTREGADO`).
  final String estadoTurno;

  /// true si su cuota la cubrió el número muerto porque no pagó a tiempo (AP-10).
  final bool cubiertoPorNumeroMuerto;

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
    this.estadoTurno = 'PENDIENTE',
    this.cubiertoPorNumeroMuerto = false,
    this.idPayment,
    this.montoPagado = 0,
    this.fechaPago,
  });

  /// Chip de estado del turno (`Al día`, `En riesgo` o `Cubierto`).
  EstadoTurnoSeguimiento get estadoTurnoChip => EstadoTurnoSeguimiento.fromValores(
        estadoTurno: estadoTurno,
        cubiertoPorNumeroMuerto: cubiertoPorNumeroMuerto,
      );

  @override
  List<Object?> get props => [
        idNumber,
        numeroTurno,
        nombre,
        isDeadNumber,
        estadoPago,
        estadoTurno,
        cubiertoPorNumeroMuerto,
        idPayment,
        montoPagado,
        fechaPago,
      ];
}

/// El número muerto de la tanda: su estado y cuánto ha cubierto (AP-10).
class NumeroMuertoSeguimiento extends Equatable {
  final int idNumber;
  final int numeroTurno;
  final String estadoTurno;
  final int pagosCubiertos;
  final double montoCubierto;

  const NumeroMuertoSeguimiento({
    required this.idNumber,
    this.numeroTurno = 0,
    this.estadoTurno = 'PENDIENTE',
    this.pagosCubiertos = 0,
    this.montoCubierto = 0,
  });

  bool get fueUsado => pagosCubiertos > 0 || montoCubierto > 0;

  EstadoTurnoSeguimiento get estadoTurnoChip => EstadoTurnoSeguimiento.fromValores(
        estadoTurno: estadoTurno,
        cubiertoPorNumeroMuerto: fueUsado,
      );

  @override
  List<Object?> get props => [
        idNumber,
        numeroTurno,
        estadoTurno,
        pagosCubiertos,
        montoCubierto,
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

  /// null si la tanda no tiene número muerto.
  final NumeroMuertoSeguimiento? numeroMuerto;

  const SeguimientoTanda({
    required this.idTanda,
    required this.nombreTanda,
    required this.vueltaActual,
    required this.cuota,
    required this.participantes,
    this.totalVueltas,
    this.turnoVigente,
    this.numeroMuerto,
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
        numeroMuerto,
      ];
}
