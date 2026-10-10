import 'package:dio/dio.dart';
import 'package:tandea/core/constants/api_constants.dart';
import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/network/api_client.dart';
import 'package:tandea/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> register({
    required String nombre,
    required String email,
    required String password,
  });

  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<dynamic>(
        ApiConstants.loginEndpoint,
        data: <String, dynamic>{
          'email': email,
          'password': password,
        },
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final userData = rawData['data'] is Map<String, dynamic>
            ? rawData['data'] as Map<String, dynamic>
            : rawData;
        return UserModel.fromJson(userData);
      } else {
        throw const ServerException(message: 'Formato de respuesta inválido');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException(
          message: 'Credenciales inválidas. Revisa tu correo y contraseña.',
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
      final responseData = e.response?.data;
      final msg = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : null;
      throw ServerException(
        message: msg ?? e.message ?? 'Error en el servidor al autenticar.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<UserModel> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<dynamic>(
        ApiConstants.registerEndpoint,
        data: <String, dynamic>{
          'nombre': nombre,
          'email': email,
          'password': password,
        },
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final userData = rawData['data'] is Map<String, dynamic>
            ? rawData['data'] as Map<String, dynamic>
            : rawData;
        return UserModel.fromJson(userData);
      } else {
        throw const ServerException(message: 'Formato de respuesta inválido');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
      final responseData = e.response?.data;
      final msg = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : null;
      throw ServerException(
        message: msg ?? e.message ?? 'Error al registrar el usuario.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.get<dynamic>(
        ApiConstants.meEndpoint,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final userData = rawData['data'] is Map<String, dynamic>
            ? rawData['data'] as Map<String, dynamic>
            : rawData;
        return UserModel.fromJson(userData);
      } else {
        throw const ServerException(message: 'Formato de respuesta inválido');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException();
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
      throw ServerException(
        message: e.message ?? 'Error al consultar la sesión.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
