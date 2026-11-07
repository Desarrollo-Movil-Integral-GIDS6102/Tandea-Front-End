import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/notificaciones/domain/entities/notificacion_entity.dart';

abstract class NotificacionRepository {
  /// `GET /notificaciones`: bandeja del usuario con su contador de no leídas.
  Future<Result<BandejaNotificaciones>> obtenerBandeja();

  /// `PATCH /notificaciones/:id/leida`
  Future<Result<void>> marcarLeida(int idNotification);

  /// `PATCH /users/me/fcm-token`: el backend manda los push a este dispositivo.
  Future<Result<void>> registrarTokenFcm(String fcmToken);
}
