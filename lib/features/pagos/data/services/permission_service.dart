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
    // En Web o plataformas desktop la selección de archivos no requiere permisos móviles
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return true;
    }

    try {
      // En iOS y Android moderno (API 33+) se utiliza Permission.photos
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }

      // En versiones anteriores de Android (<= API 32) el acceso es vía storage
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted || storageStatus.isLimited) {
        return true;
      }

      return false;
    } catch (_) {
      return true;
    }
  }
}
