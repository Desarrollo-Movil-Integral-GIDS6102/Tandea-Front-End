import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/features/auth/presentation/utils/register_validators.dart';

void main() {
  group('RegisterValidators', () {
    test('nombre valida obligatoriedad y longitud mínima', () {
      expect(RegisterValidators.nombre(null), 'El nombre es obligatorio');
      expect(RegisterValidators.nombre('   '), 'El nombre es obligatorio');
      expect(RegisterValidators.nombre('A'),
          'El nombre debe tener al menos 2 caracteres');
      expect(RegisterValidators.nombre('Ana'), isNull);
    });

    test('email valida formato razonable', () {
      expect(RegisterValidators.email(''), 'El correo electrónico es obligatorio');
      for (final bad in ['abc', 'a@b', 'a b@c.com', '@tandea.app', 'a@.c']) {
        expect(RegisterValidators.email(bad), 'Ingresa un formato de correo válido',
            reason: bad);
      }
      for (final ok in [
        'a@b.co',
        'juan.perez+tandas@mail.empresa.com.mx',
        ' pedro@tandea.app ',
      ]) {
        expect(RegisterValidators.email(ok), isNull, reason: ok);
      }
    });

    test('edad es opcional pero debe ser válida', () {
      expect(RegisterValidators.edad(''), isNull);
      expect(RegisterValidators.edad(null), isNull);
      expect(RegisterValidators.edad('17'),
          'Debes tener al menos 18 años para participar');
      expect(RegisterValidators.edad('abc'), 'Ingresa una edad válida');
      expect(RegisterValidators.edad('200'), 'Ingresa una edad válida');
      expect(RegisterValidators.edad('18'), isNull);
    });

    group('password - seguridad y robustez', () {
      test('rechaza contraseña vacía', () {
        expect(RegisterValidators.password(''), 'La contraseña es obligatoria');
        expect(RegisterValidators.password(null), 'La contraseña es obligatoria');
      });

      test('rechaza contraseñas cortas menores a 8 caracteres', () {
        expect(RegisterValidators.minPasswordLength, 8);
        expect(RegisterValidators.password('Clave9x'),
            'La contraseña debe tener al menos 8 caracteres');
        expect(RegisterValidators.password('abc'),
            'La contraseña debe tener al menos 8 caracteres');
      });

      test('acepta una contraseña robusta de 8 caracteres', () {
        expect(RegisterValidators.password('Tnd#9vKq'), isNull);
      });

      test('rechaza secuencias numéricas obvias como 123456789', () {
        expect(RegisterValidators.password('123456789'),
            'Evita secuencias como 123456789');
        expect(RegisterValidators.password('123456789012'),
            'Evita secuencias como 123456789');
        expect(RegisterValidators.password('987654321012'),
            'Evita secuencias como 123456789');
      });

      test('rechaza secuencias alfabéticas obvias como abcdefghi', () {
        expect(RegisterValidators.password('abcdefghi'),
            'Evita secuencias como 123456789');
        expect(RegisterValidators.password('abcdefghijkl'),
            'Evita secuencias como 123456789');
      });

      test('rechaza patrones repetitivos como aaaaaaaaaaaa', () {
        expect(RegisterValidators.password('aaaaaaaaaaaa'),
            'La contraseña es demasiado común o predecible');
        expect(RegisterValidators.password('111111111111'),
            'La contraseña es demasiado común o predecible');
        expect(RegisterValidators.password('abababababab'),
            'La contraseña es demasiado común o predecible');
      });

      test('rechaza contraseñas comunes como password123', () {
        expect(RegisterValidators.password('password123'),
            'La contraseña es demasiado común o predecible');
        expect(RegisterValidators.password('password12345'),
            'La contraseña es demasiado común o predecible');
        expect(RegisterValidators.password('admin12345678'),
            'La contraseña es demasiado común o predecible');
      });

      test('rechaza contraseñas formadas exclusivamente por números', () {
        expect(RegisterValidators.password('982736154820'),
            'La contraseña no puede estar compuesta solo por números');
      });

      test('permite contraseñas robustas y frases de contraseña largas', () {
        expect(RegisterValidators.password('MiClaveSegura2026!'), isNull);
        expect(RegisterValidators.password('correct horse battery staple'), isNull);
        expect(RegisterValidators.password('un-trio-de-gatos-saltarines'), isNull);
        expect(RegisterValidators.password('el sol brilla sobre la montanha'), isNull);
      });
    });

    test('confirmPassword valida coincidencia', () {
      expect(RegisterValidators.confirmPassword('', 'MiClaveSegura2026!'),
          'Confirma tu contraseña');
      expect(RegisterValidators.confirmPassword('a', 'b'),
          'Las contraseñas no coinciden');
      expect(
        RegisterValidators.confirmPassword(
          'MiClaveSegura2026!',
          'MiClaveSegura2026!',
        ),
        isNull,
      );
    });
  });
}
