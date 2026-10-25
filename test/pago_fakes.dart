import 'dart:async';
import 'dart:convert';

import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/pagos/domain/entities/comprobante_archivo.dart';
import 'package:tandea/features/pagos/domain/entities/metodo_pago.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';
import 'package:tandea/features/pagos/domain/repositories/pago_repository.dart';

const pagoRegistradoDePrueba = PagoEntity(
  idPayment: 45,
  idNumber: 10,
  metodoPago: MetodoPago.transferencia,
  transferAmount: 1500,
  cashAmount: 0,
  totalAmount: 1500,
  status: 'PENDIENTE',
  confirmedByParticipant: true,
);

/// PNG de 1x1 para simular la foto del comprobante.
final comprobanteDePrueba = ComprobanteArchivo(
  bytes: base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  ),
  nombre: 'spei.png',
  mimeType: 'image/png',
);

/// Repositorio de pagos falso para pruebas de provider y pantalla.
class FakePagoRepository implements PagoRepository {
  Result<PagoEntity> resultado = const Success(pagoRegistradoDePrueba);

  /// Si se asigna, `registrarPago` espera a que se complete (para probar el estado "enviando").
  Completer<Result<PagoEntity>>? pendiente;

  final List<RegistrarPagoParams> llamadas = [];

  RegistrarPagoParams? get ultimaLlamada => llamadas.isEmpty ? null : llamadas.last;

  @override
  Future<Result<List<PagoEntity>>> getPagosByTanda(String tandaId) async => const Success([]);

  @override
  Future<Result<PagoEntity>> registrarPago(RegistrarPagoParams params) {
    llamadas.add(params);
    final completer = pendiente;
    if (completer != null) {
      return completer.future;
    }
    return Future.value(resultado);
  }
}
