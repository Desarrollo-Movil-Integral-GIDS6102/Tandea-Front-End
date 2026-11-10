import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/tandas/data/models/historial_tanda_model.dart';
import 'package:tandea/features/tandas/domain/entities/movimiento_historial.dart';
import 'package:tandea/features/tandas/domain/repositories/historial_tanda_repository.dart';
import 'package:tandea/features/tandas/domain/usecases/obtener_historial_tanda_usecase.dart';
import 'package:tandea/features/tandas/presentation/providers/historial_tanda_provider.dart';

MovimientoHistorial _mov(int id, {TipoMovimiento tipo = TipoMovimiento.pago}) => MovimientoHistorial(
      tipo: tipo,
      id: id,
      numero: id,
      monto: 100,
      estado: 'CONFIRMADO',
    );

/// Devuelve las páginas en orden y guarda los cursores con que se pidieron.
class _FakeHistorialRepo implements HistorialTandaRepository {
  final List<Result<PaginaHistorial>> respuestas;
  final List<String?> cursoresPedidos = [];

  _FakeHistorialRepo(this.respuestas);

  @override
  Future<Result<PaginaHistorial>> getHistorial(String idTanda, {String? cursor, int limit = 20}) async {
    cursoresPedidos.add(cursor);
    return respuestas.removeAt(0);
  }
}

HistorialTandaProvider _provider(_FakeHistorialRepo repo) =>
    HistorialTandaProvider(obtenerHistorialUseCase: ObtenerHistorialTandaUseCase(repository: repo));

void main() {
  group('HistorialTandaModel.fromJson', () {
    test('lee pagos y cobros con usuario, montos y fecha', () {
      final modelo = HistorialTandaModel.fromJson(const {
        'items': [
          {
            'tipo': 'PAGO',
            'id': 5,
            'idNumber': 10,
            'numero': 4,
            'usuario': {'idUser': 5, 'nombre': 'Diego Prueba'},
            'monto': 100,
            'transferAmount': 40,
            'cashAmount': 60,
            'estado': 'PENDIENTE',
            'fecha': '2026-11-04T23:01:36.855123Z',
          },
          {'tipo': 'COBRO', 'id': 2, 'numero': 1, 'usuario': null, 'monto': '300.00', 'estado': 'CONFIRMADO'},
        ],
        'nextCursor': 'abc',
      });

      expect(modelo.nextCursor, 'abc');
      expect(modelo.hayMas, isTrue);
      final pago = modelo.items.first;
      expect(pago.tipo, TipoMovimiento.pago);
      expect(pago.nombre, 'Diego Prueba');
      expect(pago.metodo, 'Híbrido');
      expect(pago.etiquetaEstado, 'Pendiente');
      expect(pago.fecha, DateTime.utc(2026, 11, 4, 23, 1, 36, 855, 123));
      final cobro = modelo.items.last;
      expect(cobro.tipo, TipoMovimiento.cobro);
      expect(cobro.monto, 300);
      expect(cobro.nombre, isNull);
    });

    test('sin nextCursor no hay más páginas', () {
      expect(HistorialTandaModel.fromJson(const {'items': <dynamic>[], 'nextCursor': null}).hayMas, isFalse);
    });
  });

  group('HistorialTandaProvider', () {
    test('carga la primera página y luego pide la siguiente con el cursor', () async {
      final repo = _FakeHistorialRepo([
        Success(PaginaHistorial(items: [_mov(3), _mov(2)], nextCursor: 'c1')),
        Success(PaginaHistorial(items: [_mov(1, tipo: TipoMovimiento.cobro)])),
      ]);
      final provider = _provider(repo);

      await provider.cargar('7');
      expect(provider.movimientos.map((m) => m.id), [3, 2]);
      expect(provider.hayMas, isTrue);

      await provider.cargarMas();
      expect(provider.movimientos.map((m) => m.id), [3, 2, 1]);
      expect(provider.hayMas, isFalse);
      expect(repo.cursoresPedidos, [null, 'c1']);

      // Sin más páginas no vuelve a pedir
      await provider.cargarMas();
      expect(repo.cursoresPedidos, hasLength(2));
    });

    test('un error al pedir más conserva lo ya cargado', () async {
      final repo = _FakeHistorialRepo([
        Success(PaginaHistorial(items: [_mov(2)], nextCursor: 'c1')),
        const Error(NetworkFailure('Sin conexión')),
      ]);
      final provider = _provider(repo);

      await provider.cargar('7');
      await provider.cargarMas();

      expect(provider.movimientos.map((m) => m.id), [2]);
      expect(provider.errorMessage, 'Sin conexión');
      expect(provider.hayMas, isTrue);
    });

    test('marca vacío cuando la tanda no tiene movimientos', () async {
      final provider = _provider(_FakeHistorialRepo([const Success(PaginaHistorial(items: []))]));

      await provider.cargar('7');

      expect(provider.vacio, isTrue);
    });
  });
}
