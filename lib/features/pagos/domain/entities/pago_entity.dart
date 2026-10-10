import 'package:equatable/equatable.dart';

/// Entidad pura del dominio que modela un pago en una tanda.
class PagoEntity extends Equatable {
  final String id;
  final String tandaId;
  final String usuarioId;
  final double monto;
  final DateTime fecha;
  final String estado;
  final String? comprobanteUrl;

  const PagoEntity({
    required this.id,
    required this.tandaId,
    required this.usuarioId,
    required this.monto,
    required this.fecha,
    required this.estado,
    this.comprobanteUrl,
  });

  @override
  List<Object?> get props => [id, tandaId, usuarioId, monto, fecha, estado, comprobanteUrl];
}
