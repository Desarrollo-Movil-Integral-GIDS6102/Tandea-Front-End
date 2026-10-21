import 'package:equatable/equatable.dart';

/// Indicador del estado de pago de la tanda para el usuario.
enum IndicadorPago {
  alDia,
  pendiente;

  String get label => this == IndicadorPago.alDia ? 'Al día' : 'Pendiente';
  bool get esAlDia => this == IndicadorPago.alDia;
  bool get esPendiente => this == IndicadorPago.pendiente;
}

/// Entidad pura del dominio que representa una tanda de ahorro rotativo.
class TandaEntity extends Equatable {
  final String id;
  final String nombre;
  final double monto;
  final int totalParticipantes;
  final String periodo;
  final String estado;
  final String? inviteCode;
  final String? startDate;
  final int? graceDays;
  final bool? hasDeadNumber;
  final int? idTandaType;
  final IndicadorPago indicadorPago;
  final String? rolUsuario;

  const TandaEntity({
    required this.id,
    required this.nombre,
    required this.monto,
    required this.totalParticipantes,
    required this.periodo,
    required this.estado,
    this.inviteCode,
    this.startDate,
    this.graceDays,
    this.hasDeadNumber,
    this.idTandaType,
    this.indicadorPago = IndicadorPago.alDia,
    this.rolUsuario,
  });

  TandaEntity copyWith({
    String? id,
    String? nombre,
    double? monto,
    int? totalParticipantes,
    String? periodo,
    String? estado,
    String? inviteCode,
    String? startDate,
    int? graceDays,
    bool? hasDeadNumber,
    int? idTandaType,
    IndicadorPago? indicadorPago,
    String? rolUsuario,
  }) {
    return TandaEntity(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      monto: monto ?? this.monto,
      totalParticipantes: totalParticipantes ?? this.totalParticipantes,
      periodo: periodo ?? this.periodo,
      estado: estado ?? this.estado,
      inviteCode: inviteCode ?? this.inviteCode,
      startDate: startDate ?? this.startDate,
      graceDays: graceDays ?? this.graceDays,
      hasDeadNumber: hasDeadNumber ?? this.hasDeadNumber,
      idTandaType: idTandaType ?? this.idTandaType,
      indicadorPago: indicadorPago ?? this.indicadorPago,
      rolUsuario: rolUsuario ?? this.rolUsuario,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        monto,
        totalParticipantes,
        periodo,
        estado,
        inviteCode,
        startDate,
        graceDays,
        hasDeadNumber,
        idTandaType,
        indicadorPago,
        rolUsuario,
      ];
}

