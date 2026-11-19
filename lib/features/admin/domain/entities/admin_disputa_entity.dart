import 'package:equatable/equatable.dart';

/// Entidad pura del dominio que representa un caso o disputa reportada en la plataforma.
class AdminDisputaEntity extends Equatable {
  final int idDispute;
  final int idTanda;
  final String nombreTanda;
  final int idReporter;
  final String nombreReporter;
  final String emailReporter;
  final int? idResolver;
  final String reason;

  /// Estados posibles: `ABIERTA`, `EN_REVISION`, `RESUELTA`, `DESCARTADA`.
  final String status;
  final String? resolutionNotes;
  final int? idPayment;
  final int? idPayout;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  const AdminDisputaEntity({
    required this.idDispute,
    required this.idTanda,
    required this.nombreTanda,
    required this.idReporter,
    required this.nombreReporter,
    required this.emailReporter,
    this.idResolver,
    required this.reason,
    required this.status,
    this.resolutionNotes,
    this.idPayment,
    this.idPayout,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  bool get estaAbierta => status.toUpperCase() == 'ABIERTA';
  bool get estaEnRevision => status.toUpperCase() == 'EN_REVISION';
  bool get estaResuelta => status.toUpperCase() == 'RESUELTA';
  bool get estaDescartada => status.toUpperCase() == 'DESCARTADA';

  /// Un caso puede resolverse mientras esté abierto o en revisión.
  bool get puedeResolverse => estaAbierta || estaEnRevision;

  AdminDisputaEntity copyWith({
    int? idDispute,
    int? idTanda,
    String? nombreTanda,
    int? idReporter,
    String? nombreReporter,
    String? emailReporter,
    int? idResolver,
    String? reason,
    String? status,
    String? resolutionNotes,
    int? idPayment,
    int? idPayout,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return AdminDisputaEntity(
      idDispute: idDispute ?? this.idDispute,
      idTanda: idTanda ?? this.idTanda,
      nombreTanda: nombreTanda ?? this.nombreTanda,
      idReporter: idReporter ?? this.idReporter,
      nombreReporter: nombreReporter ?? this.nombreReporter,
      emailReporter: emailReporter ?? this.emailReporter,
      idResolver: idResolver ?? this.idResolver,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      idPayment: idPayment ?? this.idPayment,
      idPayout: idPayout ?? this.idPayout,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  List<Object?> get props => [
        idDispute,
        idTanda,
        nombreTanda,
        idReporter,
        nombreReporter,
        emailReporter,
        idResolver,
        reason,
        status,
        resolutionNotes,
        idPayment,
        idPayout,
        createdAt,
        updatedAt,
        resolvedAt,
      ];
}
