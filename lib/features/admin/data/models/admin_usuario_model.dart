import 'package:tandea/features/admin/domain/entities/admin_usuario_entity.dart';

/// Modelo DTO para serializar/deserializar usuarios en `/api/v1/admin/usuarios`.
class AdminUsuarioModel extends AdminUsuarioEntity {
  const AdminUsuarioModel({
    required super.idUser,
    required super.name,
    required super.lastName,
    required super.email,
    required super.role,
    required super.active,
    super.createdAt,
  });

  factory AdminUsuarioModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['idUser'] ?? json['id'] ?? 0;
    final idUser = rawId is num
        ? rawId.toInt()
        : int.tryParse(rawId.toString()) ?? 0;

    final rawCreatedAt = json['createdAt'];

    return AdminUsuarioModel(
      idUser: idUser,
      name: (json['name'] ?? json['nombre'] ?? '').toString(),
      lastName: (json['lastName'] ?? json['apellido'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? json['rol'] ?? 'usuario').toString(),
      active: json['active'] is bool ? json['active'] as bool : true,
      createdAt: rawCreatedAt != null
          ? DateTime.tryParse(rawCreatedAt.toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'idUser': idUser,
        'name': name,
        'lastName': lastName,
        'email': email,
        'role': role,
        'active': active,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  AdminUsuarioEntity toEntity() => this;
}
