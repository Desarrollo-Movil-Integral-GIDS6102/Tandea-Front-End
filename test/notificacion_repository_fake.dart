import 'package:tandea/core/errors/failures.dart';
import 'package:tandea/core/utils/result.dart';
import 'package:tandea/features/notificaciones/domain/entities/notificacion_entity.dart';
import 'package:tandea/features/notificaciones/domain/repositories/notificacion_repository.dart';

/// Fake en memoria de la bandeja para pruebas de widgets y del provider.
class NotificacionRepositoryFake implements NotificacionRepository {
  BandejaNotificaciones bandeja;
  bool fallarMarcarLeida;
  final List<int> marcadas = [];

  NotificacionRepositoryFake({
    this.bandeja = const BandejaNotificaciones(noLeidas: 0, notificaciones: []),
    this.fallarMarcarLeida = false,
  });

  @override
  Future<Result<BandejaNotificaciones>> obtenerBandeja() async => Success(bandeja);

  @override
  Future<Result<void>> marcarLeida(int idNotification) async {
    marcadas.add(idNotification);
    return fallarMarcarLeida ? const Error(ServerFailure('Sin conexión')) : const Success(null);
  }

  final List<String> tokens = [];

  @override
  Future<Result<void>> registrarTokenFcm(String fcmToken) async {
    tokens.add(fcmToken);
    return const Success(null);
  }
}
