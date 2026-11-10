import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Contrato para el servicio de compresión de imágenes.
abstract class ImageCompressorService {
  Future<Uint8List> comprimir(
    Uint8List bytes, {
    int calidad = 80,
    int minWidth = 1280,
    int minHeight = 1280,
  });
}

/// Implementación concreta utilizando `flutter_image_compress`.
class FlutterImageCompressorServiceImpl implements ImageCompressorService {
  @override
  Future<Uint8List> comprimir(
    Uint8List bytes, {
    int calidad = 80,
    int minWidth = 1280,
    int minHeight = 1280,
  }) async {
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        quality: calidad,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );
      if (compressed.isNotEmpty) {
        return Uint8List.fromList(compressed);
      }
      return bytes;
    } catch (_) {
      // Fallback seguro: si el compresor nativo no está disponible o falla,
      // se devuelven los bytes originales sin interrumpir el flujo.
      return bytes;
    }
  }
}
