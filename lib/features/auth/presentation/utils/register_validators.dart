/// Validaciones locales del formulario de registro.
///
/// Mejoran la experiencia de usuario detectando datos inválidos antes de
/// llamar al backend. El backend sigue siendo responsable de la validación
/// definitiva (`POST /api/v1/auth/register`).
///
/// Cada método devuelve `null` si el valor es válido o el mensaje de error
/// a mostrar junto al campo, compatible con `TextFormField.validator`.
class RegisterValidators {
  RegisterValidators._();

  /// Longitud mínima de contraseña requerida.
  static const int minPasswordLength = 12;

  /// Longitud mínima del nombre.
  static const int minNameLength = 2;

  /// Edad mínima permitida por regla de negocio.
  static const int minAge = 18;

  /// Edad máxima razonable para evitar valores sin sentido.
  static const int maxAge = 120;

  // Formato razonable: algo@dominio.tld, sin espacios. No es excesivamente
  // restrictivo (permite subdominios, '+', y TLDs largos).
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  // Contraseñas comunes y patrones conocidos
  static const Set<String> _commonPasswords = {
    'password',
    'password123',
    'password1234',
    'password12345',
    'password123456',
    'pass12345678',
    'admin12345678',
    'administrator',
    'contrasena123',
    'contraseña123',
    'contrasenasegura',
    'contraseñasegura',
    'tandea123456',
    'tandea202600',
    'welcome12345',
    'welcome123456',
    'qwerty123456',
    'iloveyou12345',
    'supersecret12',
    'changeme1234',
    'master123456',
    'default12345',
  };

  static const List<String> _commonKeywords = [
    'password123',
    'contrasena123',
    'contraseña123',
    'admin123',
    'qwerty123',
  ];

  static String? nombre(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El nombre es obligatorio';
    if (v.length < minNameLength) {
      return 'El nombre debe tener al menos $minNameLength caracteres';
    }
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El correo electrónico es obligatorio';
    if (!_emailRegex.hasMatch(v)) return 'Ingresa un formato de correo válido';
    return null;
  }

  /// Edad opcional: si se captura, debe ser un entero entre [minAge] y [maxAge].
  static String? edad(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    final edad = int.tryParse(v);
    if (edad == null) return 'Ingresa una edad válida';
    if (edad < minAge) return 'Debes tener al menos $minAge años para participar';
    if (edad > maxAge) return 'Ingresa una edad válida';
    return null;
  }

  /// Valida la robustez de la contraseña para impedir el envío de contraseñas
  /// débiles, predecibles o fáciles de adivinar.
  ///
  /// Reglas:
  /// - Rechazar campo vacío.
  /// - Rechazar contraseñas comunes (ej. 'password123').
  /// - Rechazar secuencias numéricas obvias (ej. '123456789').
  /// - Rechazar secuencias alfabéticas obvias (ej. 'abcdefghi') o secuencias de teclado.
  /// - Rechazar patrones repetitivos (ej. 'aaaaaaaaaaaa').
  /// - Rechazar contraseñas formadas exclusivamente por números.
  /// - Mínimo de [minPasswordLength] caracteres (12).
  ///
  /// Permite frases de contraseña largas que sean difíciles de adivinar
  /// (ej. 'correct horse battery staple').
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }

    if (_isCommonPassword(value)) {
      return 'La contraseña es demasiado común o predecible';
    }

    if (_hasRepetitivePattern(value)) {
      return 'La contraseña es demasiado común o predecible';
    }

    if (_hasNumericSequence(value)) {
      return 'Evita secuencias como 123456789';
    }

    if (_hasAlphabeticalSequence(value)) {
      return 'Evita secuencias como 123456789';
    }

    if (RegExp(r'^\d+$').hasMatch(value)) {
      return 'La contraseña no puede estar compuesta solo por números';
    }

    if (value.length < minPasswordLength) {
      return 'La contraseña debe tener al menos $minPasswordLength caracteres';
    }

    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != password) return 'Las contraseñas no coinciden';
    return null;
  }

  static bool _isCommonPassword(String s) {
    final lower = s.toLowerCase().trim();
    if (_commonPasswords.contains(lower)) return true;
    for (final kw in _commonKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  static bool _hasRepetitivePattern(String s) {
    if (s.isEmpty) return false;
    // Todo el string es el mismo carácter repetido: ej. aaaaaaaaaaaa
    if (RegExp(r'^(.)\1+$').hasMatch(s)) return true;

    // 4 o más repeticiones consecutivas del mismo carácter
    if (RegExp(r'(.)\1{3,}').hasMatch(s)) return true;

    // Patrón corto repetido 3 o más veces: ej. abababab, 12121212
    if (RegExp(r'(.{2,4})\1{2,}').hasMatch(s)) return true;

    // 12 o más caracteres pero sólo 1 o 2 caracteres únicos
    final unique = s.split('').toSet();
    if (s.length >= minPasswordLength && unique.length <= 2) return true;

    return false;
  }

  static bool _hasNumericSequence(String s) {
    int runCount = 1;
    int direction = 0;
    for (int i = 0; i < s.length - 1; i++) {
      final c1 = s.codeUnitAt(i);
      final c2 = s.codeUnitAt(i + 1);
      final isDigit1 = c1 >= 48 && c1 <= 57;
      final isDigit2 = c2 >= 48 && c2 <= 57;

      if (isDigit1 && isDigit2) {
        final diff = c2 - c1;
        if (diff == 1 || diff == -1) {
          if (direction == diff) {
            runCount++;
            if (runCount >= 5) return true;
          } else {
            direction = diff;
            runCount = 2;
          }
        } else {
          runCount = 1;
          direction = 0;
        }
      } else {
        runCount = 1;
        direction = 0;
      }
    }
    return false;
  }

  static bool _hasAlphabeticalSequence(String s) {
    final lower = s.toLowerCase();
    int runCount = 1;
    int direction = 0;
    for (int i = 0; i < lower.length - 1; i++) {
      final c1 = lower.codeUnitAt(i);
      final c2 = lower.codeUnitAt(i + 1);
      final isLetter1 = c1 >= 97 && c1 <= 122;
      final isLetter2 = c2 >= 97 && c2 <= 122;

      if (isLetter1 && isLetter2) {
        final diff = c2 - c1;
        if (diff == 1 || diff == -1) {
          if (direction == diff) {
            runCount++;
            if (runCount >= 5) return true;
          } else {
            direction = diff;
            runCount = 2;
          }
        } else {
          runCount = 1;
          direction = 0;
        }
      } else {
        runCount = 1;
        direction = 0;
      }
    }

    const keyboardSequences = [
      'qwerty',
      'wertyu',
      'asdfgh',
      'zxcvbn',
    ];
    for (final seq in keyboardSequences) {
      if (lower.contains(seq)) return true;
    }

    return false;
  }
}
