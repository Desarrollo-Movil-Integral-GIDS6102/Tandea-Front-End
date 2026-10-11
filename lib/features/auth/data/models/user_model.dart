import 'package:tandea/features/auth/domain/entities/user_entity.dart';

/// Modelo DTO para deserialización y serialización de usuarios.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.nombre,
    super.apellido,
    required super.email,
    required super.rol,
    super.token,
    super.edad,
    super.genero,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // 1. Extraer token si viene en la raíz (ej. POST /auth/login retorna { access_token: "...", user: { ... } })
    final token = (json['access_token'] ?? json['token']) as String?;

    // 2. Extraer mapa de datos de usuario (puede estar en 'user', 'data' o directamente en la raíz)
    final Map<String, dynamic> userMap =
        json['user'] is Map<String, dynamic>
            ? json['user'] as Map<String, dynamic>
            : (json['data'] is Map<String, dynamic>
                ? json['data'] as Map<String, dynamic>
                : json);

    // 3. Obtener id (NestJS retorna 'idUser', otros sistemas 'id' o '_id')
    final idRaw = userMap['idUser'] ?? userMap['id'] ?? userMap['_id'] ?? '';

    // 4. Obtener nombre y apellido (NestJS usa 'name' y 'lastName')
    final nombre = (userMap['name'] ?? userMap['nombre'] ?? '').toString();
    final apellido = (userMap['lastName'] ?? userMap['apellido'])?.toString();

    // 5. Obtener email y rol (NestJS usa 'role', otros 'rol')
    final email = (userMap['email'] ?? '').toString();
    final rol = (userMap['role'] ?? userMap['rol'] ?? 'usuario').toString();

    // 6. Obtener edad y género
    final dynamic edadRaw = userMap['age'] ?? userMap['edad'];
    final int? edad = edadRaw is int
        ? edadRaw
        : (edadRaw != null ? int.tryParse(edadRaw.toString()) : null);
    final String? genero = (userMap['gender'] ?? userMap['genero'])?.toString();

    // 7. Token en userMap o resuelto de raíz
    final resolvedToken =
        token ?? (userMap['token'] ?? userMap['access_token']) as String?;

    return UserModel(
      id: idRaw.toString(),
      nombre: nombre,
      apellido: apellido,
      email: email,
      rol: rol,
      token: resolvedToken,
      edad: edad,
      genero: genero,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      if (apellido != null) 'apellido': apellido,
      'email': email,
      'rol': rol,
      if (token != null) 'token': token,
      if (edad != null) 'edad': edad,
      if (genero != null) 'genero': genero,
    };
  }

  UserEntity toEntity() => UserEntity(
        id: id,
        nombre: nombre,
        apellido: apellido,
        email: email,
        rol: rol,
        token: token,
        edad: edad,
        genero: genero,
      );
}

