import 'package:dio/dio.dart';
import 'package:tandea/core/constants/api_constants.dart';
import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/network/api_client.dart';
import 'package:tandea/core/network/network_error_handler.dart';
import 'package:tandea/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> register({
    required String email,
    required String password,
    String? nombre,
    String? apellido,
    int? edad,
    String? genero,
  });

  Future<UserModel> getCurrentUser();
}

/// Implementación del origen de datos remoto de autenticación utilizando ApiClient.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post<dynamic>(
        ApiConstants.loginEndpoint,
        data: <String, dynamic>{
          'email': email.trim(),
          'password': password,
        },
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        return UserModel.fromJson(rawData);
      } else {
        throw const ServerException(message: 'Formato de respuesta inválido');
      }
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(e, fallbackMessage: 'Error al iniciar sesión');
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    String? nombre,
    String? apellido,
    int? edad,
    String? genero,
  }) async {
    // TODO(BE-AUTH): El backend desplegado en Railway aún NO tiene implementado el endpoint POST /api/v1/auth/register.
    // Body esperado por implementar en el backend:
    // {
    //   "email": "correo@ejemplo.com",
    //   "password": "PasswordSegura123!",
    //   "name": "Nombre",
    //   "lastName": "Apellido",
    //   "age": 25,
    //   "gender": "M"
    // }
    try {
      final data = <String, dynamic>{
        'email': email.trim(),
        'password': password,
        if (nombre != null && nombre.trim().isNotEmpty) 'name': nombre.trim(),
        if (apellido != null && apellido.trim().isNotEmpty) 'lastName': apellido.trim(),
        'age': ?edad,
        if (genero != null && genero.trim().isNotEmpty) 'gender': genero.trim(),
      };

      final response = await apiClient.post<dynamic>(
        ApiConstants.registerEndpoint,
        data: data,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        return UserModel.fromJson(rawData);
      } else {
        throw const ServerException(message: 'Formato de respuesta inválido al registrar');
      }
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(e, fallbackMessage: 'Error al registrar el usuario');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await apiClient.get<dynamic>(
        ApiConstants.profileEndpoint,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        return UserModel.fromJson(rawData);
      } else {
        throw const ServerException(message: 'Formato de respuesta inválido');
      }
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(e, fallbackMessage: 'Error al consultar la sesión');
    }
  }

}
