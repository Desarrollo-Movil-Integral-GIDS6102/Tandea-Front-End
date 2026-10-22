import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Archivo del comprobante de pago (JPG, PNG o PDF) listo para enviarse.
///
/// Se maneja como bytes para que funcione igual en móvil y en web.
class ComprobanteArchivo extends Equatable {
  final Uint8List bytes;
  final String nombre;
  final String mimeType;

  const ComprobanteArchivo({
    required this.bytes,
    required this.nombre,
    required this.mimeType,
  });

  @override
  List<Object?> get props => [bytes, nombre, mimeType];
}
