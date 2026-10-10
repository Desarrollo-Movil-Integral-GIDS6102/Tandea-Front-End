import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/auth/domain/entities/user_entity.dart';

/// Contrato abstracto del repositorio de autenticación en la capa de dominio.
abstract class AuthRepository {
  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Result<UserEntity>> register({
    required String nombre,
    required String email,
    required String password,
  });

  Future<Result<UserEntity>> getCurrentUser();

  Future<Result<void>> logout();

  Future<bool> isAuthenticated();
}
