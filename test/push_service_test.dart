import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/features/auth/domain/entities/user_role.dart';
import 'package:tandea/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:tandea/features/notificaciones/data/services/push_service.dart';

import 'notificacion_repository_fake.dart';

void main() {
  group('rutaDeMensaje', () {
    test('devuelve la ruta interna que manda el backend', () {
      expect(rutaDeMensaje({'route': '/entregas/21'}), '/entregas/21');
    });

    test('ignora datos sin ruta o con una URL externa', () {
      expect(rutaDeMensaje({}), isNull);
      expect(rutaDeMensaje({'route': 'https://otro.sitio'}), isNull);
      expect(rutaDeMensaje({'route': '//otro.sitio/x'}), isNull);
    });
  });

  group('TokenFcmSync', () {
    late NotificacionRepositoryFake repo;
    late AuthSessionProvider sesion;
    late TokenFcmSync sync;

    setUp(() {
      repo = NotificacionRepositoryFake();
      sesion = AuthSessionProvider();
      sync = TokenFcmSync(repositorio: repo, sesion: sesion);
    });

    test('sin sesión no manda el token; al iniciar sesión sí', () async {
      await sync.actualizarToken('tok-1');
      expect(repo.tokens, isEmpty);

      sesion.setSession(token: 'jwt-a', role: UserRole.usuario);
      await Future<void>.delayed(Duration.zero);
      expect(repo.tokens, ['tok-1']);
    });

    test('no repite el mismo token en la misma sesión, pero sí al cambiar de cuenta', () async {
      sesion.setSession(token: 'jwt-a', role: UserRole.usuario);
      await sync.actualizarToken('tok-1');
      await sync.actualizarToken('tok-1');
      expect(repo.tokens, ['tok-1']);

      sesion.clearSession();
      sesion.setSession(token: 'jwt-b', role: UserRole.usuario);
      await Future<void>.delayed(Duration.zero);
      expect(repo.tokens, ['tok-1', 'tok-1']);
    });

    test('un token nuevo de Firebase se vuelve a mandar', () async {
      sesion.setSession(token: 'jwt-a', role: UserRole.usuario);
      await sync.actualizarToken('tok-1');
      await sync.actualizarToken('tok-2');
      expect(repo.tokens, ['tok-1', 'tok-2']);
    });
  });
}
