import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/core/utils/formato_moneda.dart';

void main() {
  group('formatearMonedaMxn', () {
    test('agrega separador de miles y 2 decimales', () {
      expect(formatearMonedaMxn(1500), r'$1,500.00');
      expect(formatearMonedaMxn(1234567.891), r'$1,234,567.89');
      expect(formatearMonedaMxn(999), r'$999.00');
      expect(formatearMonedaMxn(0), r'$0.00');
    });

    test('redondea a centavos sin errores de punto flotante', () {
      expect(formatearMonedaMxn(0.1 + 0.2), r'$0.30');
    });
  });

  group('formatearMontoApi', () {
    test('envía 2 decimales exactos sin separador de miles', () {
      expect(formatearMontoApi(1500), '1500.00');
      expect(formatearMontoApi(0.1 + 0.2), '0.30');
      expect(formatearMontoApi(600.005), '600.01');
    });
  });

  group('parsearMonto', () {
    test('acepta enteros, decimales y separadores de miles', () {
      expect(parsearMonto('1500'), 1500);
      expect(parsearMonto('1,500.50'), 1500.50);
      expect(parsearMonto(r'$ 20.5'), 20.5);
    });

    test('devuelve null si está vacío o no es número', () {
      expect(parsearMonto(''), isNull);
      expect(parsearMonto('   '), isNull);
      expect(parsearMonto('abc'), isNull);
    });
  });
}
