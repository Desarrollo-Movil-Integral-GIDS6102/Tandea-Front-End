import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/pagos/data/services/image_compressor_service.dart';
import 'package:tandea/features/pagos/data/services/permission_service.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';
import 'package:tandea/features/pagos/domain/entities/origen_imagen.dart';
import 'package:tandea/features/pagos/domain/services/comprobante_service.dart';
import 'package:tandea/features/pagos/domain/usecases/seleccionar_comprobante_usecase.dart';

final dummyImageBytes = Uint8List.fromList(List.generate(100, (i) => i % 256));
final dummyCompressedBytes = Uint8List.fromList(List.generate(50, (i) => (i * 2) % 256));

final comprobanteDePrueba = ComprobanteArchivo(
  bytes: dummyCompressedBytes,
  nombre: 'comprobante_test.jpg',
  mimeType: 'image/jpeg',
);

class FakePermissionService implements PermissionService {
  bool permisoCamaraConcedido = true;
  bool permisoGaleriaConcedido = true;
  int llamadasCamara = 0;
  int llamadasGaleria = 0;

  @override
  Future<bool> solicitarPermisoCamara() async {
    llamadasCamara++;
    return permisoCamaraConcedido;
  }

  @override
  Future<bool> solicitarPermisoGaleria() async {
    llamadasGaleria++;
    return permisoGaleriaConcedido;
  }
}

class FakeImageCompressorService implements ImageCompressorService {
  Uint8List resultadoCompresion = dummyCompressedBytes;
  int llamadas = 0;
  Uint8List? ultimosBytesRecibidos;

  @override
  Future<Uint8List> comprimir(
    Uint8List bytes, {
    int calidad = 80,
    int minWidth = 1280,
    int minHeight = 1280,
  }) async {
    llamadas++;
    ultimosBytesRecibidos = bytes;
    return resultadoCompresion;
  }
}

class FakeImagePicker extends ImagePicker {
  XFile? archivoARetornar;
  ImageSource? ultimaFuente;
  int llamadas = 0;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    llamadas++;
    ultimaFuente = source;
    return archivoARetornar;
  }
}

class FakeComprobanteService implements ComprobanteService {
  Result<ComprobanteArchivo?> resultado = Success(comprobanteDePrueba);
  OrigenImagen? ultimoOrigen;
  int llamadas = 0;

  @override
  Future<Result<ComprobanteArchivo?>> obtenerComprobante(OrigenImagen origen) async {
    llamadas++;
    ultimoOrigen = origen;
    return resultado;
  }
}

class FakeSeleccionarComprobanteUseCase extends SeleccionarComprobanteUseCase {
  FakeSeleccionarComprobanteUseCase({ComprobanteService? service})
      : super(comprobanteService: service ?? FakeComprobanteService());
}
