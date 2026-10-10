import 'package:equatable/equatable.dart';

/// Entidad pura del dominio que representa a un usuario dentro del sistema Tandea.
class UserEntity extends Equatable {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final String? token;

  const UserEntity({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.token,
  });

  @override
  List<Object?> get props => [id, nombre, email, rol, token];
}
