import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tandea/features/notificaciones/domain/repositories/notificacion_repository.dart';
import 'package:tandea/features/notificaciones/presentation/providers/notificacion_provider.dart';

/// Recepción de notificaciones push con Firebase Cloud Messaging.
///
/// Firebase se configura con `FIREBASE_*` en el `.env` (sin `google-services.json`).
/// Si faltan, el push queda apagado y la app sigue funcionando con la bandeja.
class PushService {
  /// Para mostrar el aviso cuando la app está abierta (onMessage no lo muestra el sistema).
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  final GoRouter router;
  final NotificacionProvider bandeja;
  final TokenFcmSync tokenSync;

  PushService({required this.router, required this.bandeja, required this.tokenSync});

  Future<void> iniciar() async {
    final opciones = opcionesDesdeEnv();
    if (opciones == null) {
      debugPrint('Push desactivado: faltan las variables FIREBASE_* en .env');
      return;
    }
    try {
      await Firebase.initializeApp(options: opciones);
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      FirebaseMessaging.onMessage.listen(_enPrimerPlano);
      FirebaseMessaging.onMessageOpenedApp.listen(_abrir);
      // shortcut: getToken/onTokenRefresh están deprecados por register()/onRegistered (ID de
      // instalación), pero el backend manda con `send({ token })`; migrar ambos lados a la vez.
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen(tokenSync.actualizarToken);
      // ignore: deprecated_member_use
      await tokenSync.actualizarToken(await messaging.getToken());

      // La app se abrió tocando una notificación estando cerrada
      final inicial = await messaging.getInitialMessage();
      if (inicial != null) _abrir(inicial);
    } catch (e) {
      // Sin Play Services o con datos de Firebase inválidos: la app sigue sin push
      debugPrint('No se pudo iniciar el push: $e');
    }
  }

  void _enPrimerPlano(RemoteMessage mensaje) {
    bandeja.cargar();
    final titulo = mensaje.notification?.title;
    final cuerpo = mensaje.notification?.body;
    if (titulo == null && cuerpo == null) return;
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text([titulo, cuerpo].whereType<String>().join('\n')),
        action: rutaDeMensaje(mensaje.data) == null
            ? null
            : SnackBarAction(label: 'Ver', onPressed: () => _abrir(mensaje)),
      ),
    );
  }

  void _abrir(RemoteMessage mensaje) {
    bandeja.cargar();
    final ruta = rutaDeMensaje(mensaje.data);
    if (ruta != null) router.push(ruta);
  }

  static FirebaseOptions? opcionesDesdeEnv() {
    String? leer(String clave) {
      final valor = dotenv.isInitialized ? dotenv.maybeGet(clave) : null;
      return valor == null || valor.isEmpty ? null : valor;
    }

    final apiKey = leer('FIREBASE_API_KEY');
    final appId = leer('FIREBASE_APP_ID');
    final senderId = leer('FIREBASE_MESSAGING_SENDER_ID');
    final projectId = leer('FIREBASE_PROJECT_ID');
    if (apiKey == null || appId == null || senderId == null || projectId == null) return null;
    return FirebaseOptions(apiKey: apiKey, appId: appId, messagingSenderId: senderId, projectId: projectId);
  }
}

/// Ruta interna a abrir según `data.route` del push; solo rutas de la app (empiezan con `/`).
String? rutaDeMensaje(Map<String, dynamic> data) {
  final ruta = data['route'];
  return ruta is String && ruta.startsWith('/') && !ruta.startsWith('//') ? ruta : null;
}

/// Manda el token FCM al backend cuando hay sesión, una vez por token y por sesión.
class TokenFcmSync {
  final NotificacionRepository repositorio;
  final AuthSessionProvider sesion;

  String? _token;
  String? _enviadoPara;

  TokenFcmSync({required this.repositorio, required this.sesion}) {
    sesion.addListener(_sincronizar);
  }

  Future<void> actualizarToken(String? token) async {
    _token = token;
    await _sincronizar();
  }

  Future<void> _sincronizar() async {
    final token = _token;
    final sesionActual = sesion.token;
    if (sesionActual == null) {
      // Al cerrar sesión, la siguiente cuenta debe volver a registrar el dispositivo
      _enviadoPara = null;
      return;
    }
    final clave = '$sesionActual|$token';
    if (token == null || _enviadoPara == clave) return;
    _enviadoPara = clave;
    final result = await repositorio.registrarTokenFcm(token);
    if (result.isFailure) _enviadoPara = null;
  }
}
