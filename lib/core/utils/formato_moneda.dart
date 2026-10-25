/// Utilidades de formato de montos en pesos mexicanos.
///
/// Todo se redondea a centavos enteros antes de formatear para evitar
/// errores de punto flotante (por ejemplo `0.1 + 0.2`).
library;

/// Convierte un monto a centavos enteros.
int montoACentavos(double monto) => (monto * 100).round();

/// Formatea un monto como moneda MXN para mostrar: `1500` → `$1,500.00`.
String formatearMonedaMxn(double monto) {
  final centavos = montoACentavos(monto);
  final signo = centavos < 0 ? '-' : '';
  final absoluto = centavos.abs();
  final enteros = (absoluto ~/ 100).toString();
  final decimales = (absoluto % 100).toString().padLeft(2, '0');

  final buffer = StringBuffer();
  for (var i = 0; i < enteros.length; i++) {
    if (i > 0 && (enteros.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(enteros[i]);
  }

  return '$signo\$$buffer.$decimales';
}

/// Formatea un monto con 2 decimales exactos para enviarlo al backend: `0.1 + 0.2` → `0.30`.
String formatearMontoApi(double monto) {
  final centavos = montoACentavos(monto);
  final signo = centavos < 0 ? '-' : '';
  final absoluto = centavos.abs();
  return '$signo${absoluto ~/ 100}.${(absoluto % 100).toString().padLeft(2, '0')}';
}

/// Interpreta el texto de un campo de monto (`1500`, `1500.5`, `1,500.50`).
/// Devuelve null si está vacío o no es un número.
double? parsearMonto(String texto) {
  final limpio = texto.replaceAll(',', '').replaceAll(r'$', '').trim();
  if (limpio.isEmpty) {
    return null;
  }
  return double.tryParse(limpio);
}
