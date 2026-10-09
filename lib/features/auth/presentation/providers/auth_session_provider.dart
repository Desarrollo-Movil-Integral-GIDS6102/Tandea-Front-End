import 'package:flutter/foundation.dart';
import 'package:tandea/features/auth/domain/entities/user_role.dart';

class AuthSessionProvider extends ChangeNotifier {
  UserRole _role = UserRole.usuario;
  String? _token;

  UserRole get role => _role;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isAdminGlobal => _role.isAdminGlobal;

  void setSession({required String token, required UserRole role}) {
    _token = token;
    _role = role;
    notifyListeners();
  }

  void setRole(UserRole newRole) {
    _role = newRole;
    notifyListeners();
  }

  void clearSession() {
    _token = null;
    _role = UserRole.usuario;
    notifyListeners();
  }
}
