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
    required String email,
    required String password,
    String? nombre,
    String? apellido,
    int? edad,
    String? genero,
  });

  Future<UserModel> getCurrentUser();
}

/// Implementación del origen de datos remoto de autenticación utilizando Dio.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl({Dio? dio, ApiClient? apiClient})
      : _dio = dio ?? (apiClient?.dio ?? Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)));

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
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
      _handleDioException(e, fallbackMessage: 'Error al iniciar sesión');
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
    try {
      final data = <String, dynamic>{
        'email': email.trim(),
        'password': password,
        if (nombre != null && nombre.trim().isNotEmpty) 'name': nombre.trim(),
        if (apellido != null && apellido.trim().isNotEmpty) 'lastName': apellido.trim(),
        'age': ?edad,
        if (genero != null && genero.trim().isNotEmpty) 'gender': genero.trim(),
      };

      final response = await _dio.post<dynamic>(
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
      _handleDioException(e, fallbackMessage: 'Error al registrar el usuario');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiConstants.profileEndpoint,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        return UserModel.fromJson(rawData);
      } else {
        throw const ServerException(message: 'Formato de respuesta inválido');
      }
    } on DioException catch (e) {
      _handleDioException(e, fallbackMessage: 'Error al consultar la sesión');
    }
  }

  Never _handleDioException(DioException e, {required String fallbackMessage}) {
    if (e.response?.statusCode == 401) {
      throw UnauthorizedException(
        message: _extractErrorMessage(e) ?? 'Credenciales inválidas. Revisa tu correo y contraseña.',
      );
    }
    if (e.response?.statusCode == 409) {
      throw ServerException(
        message: _extractErrorMessage(e) ?? 'El correo electrónico ya está registrado.',
        statusCode: 409,
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw const NetworkException();
    }
    final message = _extractErrorMessage(e) ?? e.message ?? fallbackMessage;
    throw ServerException(
      message: message,
      statusCode: e.response?.statusCode,
    );
  }

  String? _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message is List) {
        return message.map((item) => item.toString()).join('\n');
      }
      if (message != null) {
        return message.toString();
      }
    }
    return null;
  }
}
