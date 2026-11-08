import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tandea/features/notificaciones/domain/entities/notificacion_entity.dart';
import 'package:tandea/features/notificaciones/presentation/providers/notificacion_provider.dart';
import 'package:tandea/features/notificaciones/presentation/widgets/campana_notificaciones.dart';

import 'notificacion_repository_fake.dart';

NotificacionEntity _notif(int id, {bool leida = false}) => NotificacionEntity(
      idNotification: id,
      idTanda: 3,
      nombreTanda: 'Tanda oficina',
      tipo: 'pago_confirmado',
      mensaje: 'Tu pago fue confirmado',
      leida: leida,
      fecha: DateTime(2026, 11, 7, 9),
    );

void main() {
  test('BandejaNotificaciones.fromJson lee la respuesta del backend', () {
    final bandeja = BandejaNotificaciones.fromJson({
      'noLeidas': 1,
      'notificaciones': [
        {
          'idNotification': 5,
          'idTanda': null,
          'nombreTanda': null,
          'type': 'recordatorio_pago',
          'message': 'Recuerda tu pago',
          'isRead': false,
          'createdAt': '2026-11-07T15:00:00.000Z',
        },
      ],
    });

    expect(bandeja.noLeidas, 1);
    expect(bandeja.notificaciones.single.idNotification, 5);
    expect(bandeja.notificaciones.single.idTanda, isNull);
    expect(bandeja.notificaciones.single.leida, isFalse);
  });

  group('NotificacionProvider', () {
    test('marcarLeida baja el contador y llama al backend', () async {
      final repo = NotificacionRepositoryFake(
        bandeja: BandejaNotificaciones(noLeidas: 2, notificaciones: [_notif(1), _notif(2)]),
      );
      final provider = NotificacionProvider(notificacionRepository: repo);
      await provider.cargar();

      await provider.marcarLeida(provider.notificaciones.first);

      expect(provider.noLeidas, 1);
      expect(provider.notificaciones.first.leida, isTrue);
      expect(repo.marcadas, [1]);
    });

    test('marcarLeida revierte si el backend falla', () async {
      final repo = NotificacionRepositoryFake(
        bandeja: BandejaNotificaciones(noLeidas: 1, notificaciones: [_notif(1)]),
        fallarMarcarLeida: true,
      );
      final provider = NotificacionProvider(notificacionRepository: repo);
      await provider.cargar();

      await provider.marcarLeida(provider.notificaciones.first);

      expect(provider.noLeidas, 1);
      expect(provider.notificaciones.first.leida, isFalse);
      expect(provider.errorMessage, isNotNull);
    });

    test('una notificación ya leída no vuelve a llamar al backend', () async {
      final repo = NotificacionRepositoryFake(
        bandeja: BandejaNotificaciones(noLeidas: 0, notificaciones: [_notif(1, leida: true)]),
      );
      final provider = NotificacionProvider(notificacionRepository: repo);
      await provider.cargar();

      await provider.marcarLeida(provider.notificaciones.first);

      expect(repo.marcadas, isEmpty);
    });
  });

  testWidgets('la campana muestra el contador de no leídas', (tester) async {
    final provider = NotificacionProvider(
      notificacionRepository: NotificacionRepositoryFake(
        bandeja: BandejaNotificaciones(noLeidas: 3, notificaciones: [_notif(1), _notif(2), _notif(3)]),
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: CampanaNotificaciones())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
  });
}
