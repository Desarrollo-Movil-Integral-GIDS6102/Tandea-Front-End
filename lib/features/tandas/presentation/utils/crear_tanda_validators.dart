/// Validaciones locales del formulario de creación de tandas.
///
/// Garantiza el cumplimiento de las reglas de negocio antes de enviar datos al
/// backend (`POST /api/v1/tandas`).
class CrearTandaValidators {
  CrearTandaValidators._();

  /// Mínimo de participantes permitidos en una tanda según la regla de negocio (QA-03).
  static const int minParticipantes = 3;

  /// Límite máximo de participantes permitidos.
  static const int maxParticipantes = 50;

  /// Mensaje exacto de validación cuando no se cumple el mínimo de participantes.
  static const String mensajeMinParticipantes =
      'Una tanda requiere al menos 3 participantes';

  /// Valida la cantidad de participantes ingresada en el formulario.
  ///
  /// Reglas:
  /// - Rechaza valores nulos, vacíos o que solo contienen espacios en blanco.
  /// - Rechaza valores no numéricos o valores decimales.
  /// - Rechaza cantidades inferiores a [minParticipantes] (ej. 0, 1, 2).
  /// - Rechaza cantidades superiores a [maxParticipantes] (50).
  /// - Acepta cantidades enteras mayores o iguales a 3 y menores o iguales a 50.
  ///
  /// Retorna el mensaje de error correspondiente o `null` si el valor es válido.
  static String? participantes(String? value) {
    if (value == null) {
      return mensajeMinParticipantes;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return mensajeMinParticipantes;
    }

    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < minParticipantes) {
      return mensajeMinParticipantes;
    }

    if (parsed > maxParticipantes) {
      return 'Máx. $maxParticipantes';
    }

    return null;
  }
}
