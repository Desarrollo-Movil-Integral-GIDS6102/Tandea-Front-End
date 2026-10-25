import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/features/tandas/presentation/utils/crear_tanda_validators.dart';

void main() {
  group('CrearTandaValidators - Regla de participantes mínimos (QA-03)', () {
    const expectedError = 'Una tanda requiere al menos 3 participantes';

    test('campo vacío es rechazado con el mensaje exacto', () {
      expect(CrearTandaValidators.participantes(''), equals(expectedError));
      expect(CrearTandaValidators.participantes('   '), equals(expectedError));
      expect(CrearTandaValidators.participantes(null), equals(expectedError));
    });

    test('0 participantes es rechazado con el mensaje exacto', () {
      expect(CrearTandaValidators.participantes('0'), equals(expectedError));
    });

    test('1 participante es rechazado con el mensaje exacto', () {
      expect(CrearTandaValidators.participantes('1'), equals(expectedError));
    });

    test('2 participantes es rechazado con el mensaje exacto', () {
      expect(CrearTandaValidators.participantes('2'), equals(expectedError));
    });

    test('3 participantes es aceptado (retorna null)', () {
      expect(CrearTandaValidators.participantes('3'), isNull);
    });

    test('más de 3 participantes es aceptado si no supera el límite de 50', () {
      expect(CrearTandaValidators.participantes('4'), isNull);
      expect(CrearTandaValidators.participantes('5'), isNull);
      expect(CrearTandaValidators.participantes('10'), isNull);
      expect(CrearTandaValidators.participantes('25'), isNull);
      expect(CrearTandaValidators.participantes('50'), isNull);
    });

    test('más de 50 participantes es rechazado con límite superior', () {
      expect(CrearTandaValidators.participantes('51'), equals('Máx. 50'));
      expect(CrearTandaValidators.participantes('99'), equals('Máx. 50'));
    });

    test('valores no numéricos, decimales y negativos son rechazados', () {
      expect(CrearTandaValidators.participantes('abc'), equals(expectedError));
      expect(CrearTandaValidators.participantes('3.5'), equals(expectedError));
      expect(CrearTandaValidators.participantes('-1'), equals(expectedError));
      expect(CrearTandaValidators.participantes('2,5'), equals(expectedError));
    });
  });
}
