import 'package:equatable/equatable.dart';

/// Aviso de la bandeja del usuario (`GET /notificaciones`).
class NotificacionEntity extends Equatable {
  final int idNotification;
  final int? idTanda;
  final String? nombreTanda;

  /// pago_registrado, pago_confirmado, pago_rechazado, recordatorio_pago...
  final String tipo;
  final String mensaje;
  final bool leida;
  final DateTime fecha;

  const NotificacionEntity({
    required this.idNotification,
    required this.idTanda,
    required this.nombreTanda,
    required this.tipo,
    required this.mensaje,
    required this.leida,
    required this.fecha,
  });

  factory NotificacionEntity.fromJson(Map<String, dynamic> json) {
    return NotificacionEntity(
      idNotification: (json['idNotification'] as num).toInt(),
      idTanda: (json['idTanda'] as num?)?.toInt(),
      nombreTanda: json['nombreTanda'] as String?,
      tipo: (json['type'] ?? '').toString(),
      mensaje: (json['message'] ?? '').toString(),
      leida: json['isRead'] == true,
      fecha: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  NotificacionEntity marcadaLeida() => NotificacionEntity(
        idNotification: idNotification,
        idTanda: idTanda,
        nombreTanda: nombreTanda,
        tipo: tipo,
        mensaje: mensaje,
        leida: true,
        fecha: fecha,
      );

  @override
  List<Object?> get props => [idNotification, idTanda, nombreTanda, tipo, mensaje, leida, fecha];
}

/// Respuesta completa de la bandeja.
class BandejaNotificaciones {
  final int noLeidas;
  final List<NotificacionEntity> notificaciones;

  const BandejaNotificaciones({required this.noLeidas, required this.notificaciones});

  factory BandejaNotificaciones.fromJson(Map<String, dynamic> json) {
    return BandejaNotificaciones(
      noLeidas: (json['noLeidas'] as num?)?.toInt() ?? 0,
      notificaciones: (json['notificaciones'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(NotificacionEntity.fromJson)
          .toList(),
    );
  }
}
