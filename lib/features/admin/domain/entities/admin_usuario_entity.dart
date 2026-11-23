import 'package:equatable/equatable.dart';

/// Entidad pura del dominio que representa un usuario listado en el panel de Administración Global.
class AdminUsuarioEntity extends Equatable {
  final int idUser;
  final String name;
  final String lastName;
  final String email;
  final String role;
  final bool active;
  final DateTime? createdAt;

  const AdminUsuarioEntity({
    required this.idUser,
    required this.name,
    required this.lastName,
    required this.email,
    required this.role,
    required this.active,
    this.createdAt,
  });

  String get nombreCompleto {
    final completo = '$name $lastName'.trim();
    return completo.isEmpty ? email : completo;
  }

  bool get esAdminGlobal => role.toLowerCase() == 'admin_global';

  bool get puedeSuspenderse => active && !esAdminGlobal;

  AdminUsuarioEntity copyWith({
    int? idUser,
    String? name,
    String? lastName,
    String? email,
    String? role,
    bool? active,
    DateTime? createdAt,
  }) {
    return AdminUsuarioEntity(
      idUser: idUser ?? this.idUser,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        idUser,
        name,
        lastName,
        email,
        role,
        active,
        createdAt,
      ];
}
