import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tandea/core/constants/app_constants.dart';
import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tandea/features/auth/domain/entities/user_entity.dart';
import 'package:tandea/features/auth/domain/repositories/auth_repository.dart';

/// Implementación del repositorio de autenticación en la capa de datos.
/// Gestiona la persistencia segura del JWT en flutter_secure_storage.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage storage;
  final String tokenKey;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storage,
    this.tokenKey = AppConstants.tokenKey,
  });

  @override
  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await remoteDataSource.login(
        email: email,
        password: password,
      );

      final token = userModel.token;
      if (token != null && token.isNotEmpty) {
        await storage.write(key: tokenKey, value: token);
      }

      return Success(userModel.toEntity());
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
    required String email,
    required String password,
    String? nombre,
    String? apellido,
    int? edad,
    String? genero,
  }) async {
    try {
      final userModel = await remoteDataSource.register(
        email: email,
        password: password,
        nombre: nombre,
        apellido: apellido,
        edad: edad,
        genero: genero,
      );

      var token = userModel.token;
      // Si el endpoint de registro no devuelve el JWT inmediatamente (comportamiento estándar en NestJS),
      // se realiza un login automático con las credenciales registradas para persistir el JWT.
      if (token == null || token.isEmpty) {
        try {
          final loginResult = await remoteDataSource.login(
            email: email,
            password: password,
          );
          token = loginResult.token;
          if (token != null && token.isNotEmpty) {
            await storage.write(key: tokenKey, value: token);
            return Success(loginResult.toEntity());
          }
        } catch (_) {
          // Si el login automático falla, devolvemos el usuario recién registrado
        }
      } else {
        await storage.write(key: tokenKey, value: token);
      }

      return Success(userModel.toEntity());
    } on UnauthorizedException catch (e) {
      return Error(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message, statusCode: e.statusCode, fieldErrors: e.fieldErrors));
    } catch (e) {
      return Error(ServerFailure('Error inesperado al registrar usuario: $e'));
    }
  }

  @override
  Future<Result<UserEntity>> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentUser();
      return Success(userModel.toEntity());
    } on UnauthorizedException catch (e) {
      await storage.delete(key: tokenKey);
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
      await storage.delete(key: tokenKey);
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure('Error al cerrar sesión: $e'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await storage.read(key: tokenKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> getToken() async {
    return storage.read(key: tokenKey);
  }
}
