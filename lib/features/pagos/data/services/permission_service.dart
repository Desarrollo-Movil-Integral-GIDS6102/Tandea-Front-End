import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Contrato para la gestión de permisos del sistema operativo.
abstract class PermissionService {
  Future<bool> solicitarPermisoCamara();
  Future<bool> solicitarPermisoGaleria();
}

/// Implementación concreta de [PermissionService] usando `permission_handler`.
class PermissionServiceImpl implements PermissionService {
  @override
  Future<bool> solicitarPermisoCamara() async {
    // En Web o plataformas desktop los permisos de cámara los gestiona el navegador o sistema operativo
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return true;
    }

    try {
      final status = await Permission.camera.request();
      return status.isGranted || status.isLimited;
    } catch (_) {
      // Si ocurre alguna excepción en la plataforma, no bloquear la aplicación
      return true;
    }
  }

  @override
  Future<bool> solicitarPermisoGaleria() async {
    // image_picker usa el selector de fotos del sistema: no requiere permisos de almacenamiento.
    return true;
  }
}

