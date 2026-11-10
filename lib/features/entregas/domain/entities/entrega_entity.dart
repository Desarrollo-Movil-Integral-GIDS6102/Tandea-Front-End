import 'package:equatable/equatable.dart';

/// Entrega del dinero de un turno: la registra el organizador y la confirma quien cobra.
class EntregaEntity extends Equatable {
  final int idPayout;
  final int numero;
  final String nombreTanda;
  final double transferencia;
  final double efectivo;
  final double total;
  final bool confirmada;
  final String? evidenciaUrl;

  const EntregaEntity({
    required this.idPayout,
    required this.numero,
    required this.nombreTanda,
    required this.transferencia,
    required this.efectivo,
    required this.total,
    required this.confirmada,
    this.evidenciaUrl,
  });

  factory EntregaEntity.fromJson(Map<String, dynamic> json) {
    return EntregaEntity(
      idPayout: (json['idPayout'] as num).toInt(),
      numero: (json['numberValue'] as num).toInt(),
      nombreTanda: (json['nombreTanda'] ?? '').toString(),
      transferencia: (json['transferAmount'] as num).toDouble(),
      efectivo: (json['cashAmount'] as num).toDouble(),
      total: (json['totalAmount'] as num).toDouble(),
      confirmada: json['status'] == 'CONFIRMADO',
      evidenciaUrl: json['evidenceUrl'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [idPayout, numero, nombreTanda, transferencia, efectivo, total, confirmada, evidenciaUrl];
}
