import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tandea/core/constants/app_constants.dart';
import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tandea/features/auth/domain/entities/user_entity.dart';
import 'package:tandea/features/auth/domain/repositories/auth_repository.dart';

/// Implementación del repositorio de autenticación en la capa de datos.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final FlutterSecureStorage _storage;
  final String _tokenKey;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required FlutterSecureStorage storage,
    String tokenKey = AppConstants.tokenKey,
  })  : _remoteDataSource = remoteDataSource,
        _storage = storage,
        _tokenKey = tokenKey;

  @override
  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      final token = userModel.token;
      if (token != null && token.isNotEmpty) {
        await _storage.write(key: _tokenKey, value: token);
      }

      return Success(userModel);
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('Error inesperado al iniciar sesión: $e'));
    }
  }

  @override
  Future<Result<UserEntity>> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _remoteDataSource.register(
        nombre: nombre,
        email: email,
        password: password,
      );

      final token = userModel.token;
      if (token != null && token.isNotEmpty) {
        await _storage.write(key: _tokenKey, value: token);
      }

      return Success(userModel);
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('Error inesperado al registrar usuario: $e'));
    }
  }

  @override
  Future<Result<UserEntity>> getCurrentUser() async {
    try {
      final userModel = await _remoteDataSource.getCurrentUser();
      return Success(userModel);
    } on UnauthorizedException catch (e) {
      await _storage.delete(key: _tokenKey);
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Error(ServerFailure('Error inesperado al obtener usuario: $e'));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _storage.delete(key: _tokenKey);
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure('Error al cerrar sesión: $e'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }
}
