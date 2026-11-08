import 'package:dio/dio.dart';
import 'package:tandea/core/constants/api_constants.dart';
import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/network/api_client.dart';
import 'package:tandea/core/network/network_error_handler.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/notificaciones/domain/entities/notificacion_entity.dart';
import 'package:tandea/features/notificaciones/domain/repositories/notificacion_repository.dart';

class NotificacionRepositoryImpl implements NotificacionRepository {
  final ApiClient apiClient;

  NotificacionRepositoryImpl({required this.apiClient});

  static const _base = ApiConstants.notificacionesEndpoint;

  @override
  Future<Result<BandejaNotificaciones>> obtenerBandeja() => _ejecutar(
        () async {
          final raw = (await apiClient.get<dynamic>(_base)).data;
          if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
            return BandejaNotificaciones.fromJson(raw['data'] as Map<String, dynamic>);
          }
          throw const ServerException(message: 'Formato de respuesta inválido');
        },
        'Error al consultar las notificaciones',
      );

  @override
  Future<Result<void>> marcarLeida(int idNotification) => _ejecutar(
        () async {
          await apiClient.patch<dynamic>('$_base/$idNotification/leida');
        },
        'Error al marcar la notificación como leída',
      );

  @override
  Future<Result<void>> registrarTokenFcm(String fcmToken) => _ejecutar(
        () async {
          await apiClient.patch<dynamic>(ApiConstants.fcmTokenEndpoint, data: {'fcmToken': fcmToken});
        },
        'Error al registrar el dispositivo para notificaciones',
      );

  Future<Result<T>> _ejecutar<T>(Future<T> Function() accion, String fallback) async {
    try {
      try {
        return Success(await accion());
      } on DioException catch (e) {
        NetworkErrorHandler.handleDioException(e, fallbackMessage: fallback);
      }
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('$fallback: $e'));
    }
  }
}
