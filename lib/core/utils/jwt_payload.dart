import 'dart:convert';

/// Lee los datos de un JWT sin verificar la firma: eso lo hace el backend en cada petición.
/// Devuelve `null` si el token está mal formado.
Map<String, dynamic>? leerPayloadJwt(String token) {
  final partes = token.split('.');
  if (partes.length != 3) return null;
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(partes[1])));
    final datos = jsonDecode(payload);
    return datos is Map<String, dynamic> ? datos : null;
  } on FormatException {
    return null;
  }
}
