import 'package:dio/dio.dart';
import 'package:tandea/core/constants/api_constants.dart';
import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/network/api_client.dart';
import 'package:tandea/core/network/network_error_handler.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/auth/data/models/user_model.dart';
import 'package:tandea/features/auth/domain/entities/user_entity.dart';
import 'package:tandea/features/auth/domain/repositories/perfil_repository.dart';

/// Implementación de [PerfilRepository] contra `/auth/perfil`.
class PerfilRepositoryImpl implements PerfilRepository {
  final ApiClient apiClient;

  PerfilRepositoryImpl({required this.apiClient});

  @override
  Future<Result<UserEntity>> obtenerPerfil() => _ejecutar(
        () async => UserModel.fromJson(_mapa(
          (await apiClient.get<dynamic>(ApiConstants.perfilEndpoint)).data,
        )),
        'Error al consultar tu perfil',
      );

  @override
  Future<Result<UserEntity>> actualizarPerfil({
    required String nombre,
    required String apellido,
    int? edad,
    String? genero,
  }) =>
      _ejecutar(
        () async => UserModel.fromJson(_mapa(
          (await apiClient.patch<dynamic>(
            ApiConstants.perfilEndpoint,
            data: {
              'name': nombre.trim(),
              'lastName': apellido.trim(),
              'age': edad,
              'gender': (genero?.trim().isEmpty ?? true) ? null : genero!.trim(),
            },
          ))
              .data,
        )),
        'Error al guardar tu perfil',
      );

  @override
  Future<Result<String>> solicitarCodigoPassword() => _ejecutar(
        () async => _mensaje(
          (await apiClient.post<dynamic>(ApiConstants.perfilCodigoPasswordEndpoint)).data,
          'Te enviamos un código a tu correo',
        ),
        'Error al enviar el código',
      );

  @override
  Future<Result<String>> cambiarPassword({
    required String codigo,
    required String nuevaPassword,
  }) =>
      _ejecutar(
        () async => _mensaje(
          (await apiClient.post<dynamic>(
            ApiConstants.perfilPasswordEndpoint,
            data: {'codigo': codigo.trim(), 'nuevaPassword': nuevaPassword},
          ))
              .data,
          'Contraseña actualizada',
        ),
        'Error al cambiar la contraseña',
      );

  static Map<String, dynamic> _mapa(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    throw const ServerException(message: 'Formato de respuesta inválido');
  }

  static String _mensaje(dynamic raw, String porDefecto) =>
      raw is Map<String, dynamic> ? (raw['mensaje'] ?? porDefecto).toString() : porDefecto;

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
