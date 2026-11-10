import 'package:equatable/equatable.dart';

/// Tipo de movimiento del historial de una tanda.
enum TipoMovimiento {
  /// Aporte de un participante (`payment`).
  pago,

  /// Entrega del dinero del turno a quien le toca cobrar (`payout`).
  cobro;

  static TipoMovimiento fromValor(String? valor) =>
      valor?.trim().toUpperCase() == 'COBRO' ? TipoMovimiento.cobro : TipoMovimiento.pago;

  String get etiqueta => switch (this) {
        TipoMovimiento.pago => 'Pago',
        TipoMovimiento.cobro => 'Cobro',
      };
}

/// Un pago o un cobro de la tanda (AP-09).
class MovimientoHistorial extends Equatable {
  final TipoMovimiento tipo;
  final int id;
  final int numero;

  /// Participante dueño del número; null si no hay usuario asignado.
  final String? nombre;
  final double monto;
  final double transferAmount;
  final double cashAmount;

  /// `PENDIENTE`, `CONFIRMADO` o `RECHAZADO`.
  final String estado;
  final DateTime? fecha;

  const MovimientoHistorial({
    required this.tipo,
    required this.id,
    required this.numero,
    required this.monto,
    required this.estado,
    this.nombre,
    this.transferAmount = 0,
    this.cashAmount = 0,
    this.fecha,
  });

  bool get esConfirmado => estado.toUpperCase() == 'CONFIRMADO';
  bool get esRechazado => estado.toUpperCase() == 'RECHAZADO';

  String get etiquetaEstado => switch (estado.toUpperCase()) {
        'CONFIRMADO' => 'Confirmado',
        'RECHAZADO' => 'Rechazado',
        _ => 'Pendiente',
      };

  /// `Efectivo`, `Transferencia` o `Híbrido` según los montos.
  String get metodo {
    if (transferAmount > 0 && cashAmount > 0) return 'Híbrido';
    if (transferAmount > 0) return 'Transferencia';
    return 'Efectivo';
  }

  @override
  List<Object?> get props => [tipo, id, numero, nombre, monto, transferAmount, cashAmount, estado, fecha];
}

/// Una página de `GET /tandas/:id/historial`.
class PaginaHistorial extends Equatable {
  final List<MovimientoHistorial> items;

  /// Cursor para pedir la siguiente página; null cuando ya no hay más.
  final String? nextCursor;

  const PaginaHistorial({required this.items, this.nextCursor});

  bool get hayMas => nextCursor != null;

  @override
  List<Object?> get props => [items, nextCursor];
}
