import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;

  /// Errores de validación por campo (campo del backend → mensaje).
  final Map<String, String> fieldErrors;

  const ServerFailure(super.message, {this.statusCode, this.fieldErrors = const {}});

  @override
  List<Object?> get props => [message, statusCode, fieldErrors];
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Error de conexión. Verifica tu acceso a internet.',
  ]);
}

class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Error al consultar el almacenamiento local.',
  ]);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'No tienes autorización para realizar esta acción.',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = 'No se otorgaron los permisos necesarios.',
  ]);
}

class MediaFailure extends Failure {
  const MediaFailure([
    super.message = 'Error al procesar el archivo o comprobante.',
  ]);
}
