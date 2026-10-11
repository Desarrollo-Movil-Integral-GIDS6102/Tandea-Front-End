import 'package:equatable/equatable.dart';

/// Entidad pura del dominio que representa a un usuario dentro del sistema Tandea.
class UserEntity extends Equatable {
  final String id;
  final String nombre;
  final String? apellido;
  final String email;
  final String rol;
  final String? token;
  final int? edad;
  final String? genero;

  const UserEntity({
    required this.id,
    required this.nombre,
    this.apellido,
    required this.email,
    required this.rol,
    this.token,
    this.edad,
    this.genero,
  });

  String get nombreCompleto =>
      apellido != null && apellido!.isNotEmpty ? '$nombre $apellido' : nombre;

  @override
  List<Object?> get props => [id, nombre, apellido, email, rol, token, edad, genero];
}

