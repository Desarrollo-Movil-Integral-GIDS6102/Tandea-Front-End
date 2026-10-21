import 'package:share_plus/share_plus.dart';

/// Contrato para el servicio de compartir contenido en el sistema operativo.
abstract class ShareService {
  Future<void> shareText(String text, {String? subject});
}

/// Implementación concreta utilizando el paquete `share_plus`.
class ShareServiceImpl implements ShareService {
  @override
  Future<void> shareText(String text, {String? subject}) async {
    // ignore: deprecated_member_use
    await Share.share(text, subject: subject);
  }
}
