import 'package:tandea/features/auth/domain/entities/user_entity.dart';

/// Modelo DTO para deserialización y serialización de usuarios.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.nombre,
    required super.email,
    required super.rol,
    super.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      nombre: (json['nombre'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      rol: (json['rol'] ?? json['role'] ?? 'participante').toString(),
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      if (token != null) 'token': token,
    };
  }

  UserEntity toEntity() => this;
}
