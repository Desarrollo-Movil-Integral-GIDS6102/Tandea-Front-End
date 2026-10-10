enum UserRole {
  usuario,
  adminGlobal;

  static UserRole fromString(String? role) {
    if (role == 'admin_global' || role == 'ADMIN_GLOBAL') {
      return UserRole.adminGlobal;
    }
    return UserRole.usuario;
  }

  bool get isAdminGlobal => this == UserRole.adminGlobal;
  bool get isUsuario => this == UserRole.usuario;
}
