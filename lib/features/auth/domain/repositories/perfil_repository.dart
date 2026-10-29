import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/auth/domain/entities/user_entity.dart';

/// Perfil del usuario autenticado y cambio de contraseña con código por correo.
abstract class PerfilRepository {
  Future<Result<UserEntity>> obtenerPerfil();

  /// Solo nombre, apellido, edad y género; el correo no se puede cambiar.
  Future<Result<UserEntity>> actualizarPerfil({
    required String nombre,
    required String apellido,
    int? edad,
    String? genero,
  });

  /// Envía al correo del usuario un código de 6 dígitos. Devuelve el mensaje del backend.
  Future<Result<String>> solicitarCodigoPassword();

  Future<Result<String>> cambiarPassword({
    required String codigo,
    required String nuevaPassword,
  });
}
