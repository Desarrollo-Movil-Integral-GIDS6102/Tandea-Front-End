import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';

/// Comparación del monto que leyó el OCR en el comprobante contra el esperado.
///
/// El backend compara contra la parte por transferencia (`transferAmount`) con
/// una tolerancia de $1; aquí se usa la misma regla.
enum ResultadoOcr {
  /// El monto detectado coincide con el esperado.
  coincide,

  /// El OCR leyó un monto distinto: el organizador debe revisar el comprobante.
  noCoincide,

  /// Hay comprobante pero el OCR no pudo leer un monto.
  sinLectura,

  /// Pago solo en efectivo: no hay comprobante que leer.
  noAplica;

  static const double tolerancia = 1;

  static ResultadoOcr de(PagoEntity pago) {
    if (pago.transferAmount <= 0) {
      return ResultadoOcr.noAplica;
    }
    final detectado = pago.ocrDetectedAmount;
    if (detectado == null) {
      return ResultadoOcr.sinLectura;
    }
    if (pago.ocrVerified || (detectado - pago.transferAmount).abs() <= tolerancia) {
      return ResultadoOcr.coincide;
    }
    return ResultadoOcr.noCoincide;
  }

  String get etiqueta => switch (this) {
    ResultadoOcr.coincide => 'Coincide',
    ResultadoOcr.noCoincide => 'No coincide',
    ResultadoOcr.sinLectura => 'Sin lectura',
    ResultadoOcr.noAplica => 'No aplica',
  };
}
