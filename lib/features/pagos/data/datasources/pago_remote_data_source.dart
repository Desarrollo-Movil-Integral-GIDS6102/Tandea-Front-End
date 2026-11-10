import 'package:dio/dio.dart';
import 'package:tandea/core/constants/api_constants.dart';
import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/network/api_client.dart';
import 'package:tandea/core/network/network_error_handler.dart';
import 'package:tandea/core/utils/formato_moneda.dart';
import 'package:tandea/features/pagos/data/models/pago_model.dart';
import 'package:tandea/features/pagos/domain/repositories/pago_repository.dart';

abstract class PagoRemoteDataSource {
  Future<List<PagoModel>> getPagosByTanda(String tandaId);

  /// `POST /api/v1/pagos` como `multipart/form-data`.
  Future<PagoModel> registrarPago(RegistrarPagoParams params);

  Future<PagoModel> obtenerPago(int idPayment);
  Future<PagoModel> confirmarPago(int idPayment);
  Future<PagoModel> rechazarPago(int idPayment, String motivo);
}

class PagoRemoteDataSourceImpl implements PagoRemoteDataSource {
  final ApiClient apiClient;

  PagoRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<PagoModel>> getPagosByTanda(String tandaId) async {
    try {
      final response = await apiClient.get<dynamic>(
        ApiConstants.pagosEndpoint,
        queryParameters: <String, dynamic>{'tandaId': tandaId},
      );
      final rawData = response.data;
      final List<dynamic> list;
      if (rawData is List<dynamic>) {
        list = rawData;
      } else if (rawData is Map<String, dynamic> && rawData['data'] is List<dynamic>) {
        list = rawData['data'] as List<dynamic>;
      } else {
        list = <dynamic>[];
      }
      return list
          .whereType<Map<String, dynamic>>()
          .map(PagoModel.fromJson)
          .toList();
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(e, fallbackMessage: 'Error al consultar pagos');
    }
  }

  /// Arma el `FormData` que espera el backend. Los montos viajan como texto
  /// con 2 decimales exactos (`600.00`) para no arrastrar errores de redondeo.
  static FormData construirFormData(RegistrarPagoParams params) {
    final comprobante = params.comprobante;
    final transferAmount = params.transferAmount;
    final cashAmount = params.cashAmount;

    return FormData.fromMap(<String, dynamic>{
      'idNumber': params.idNumber.toString(),
      'metodoPago': params.metodoPago.valor,
      if (transferAmount != null) 'transferAmount': formatearMontoApi(transferAmount),
      if (cashAmount != null) 'cashAmount': formatearMontoApi(cashAmount),
      if (comprobante != null)
        'file': MultipartFile.fromBytes(
          comprobante.bytes,
          filename: comprobante.nombre,
          contentType: DioMediaType.parse(comprobante.mimeType),
        ),
    });
  }

  @override
  Future<PagoModel> registrarPago(RegistrarPagoParams params) async {
    try {
      final response = await apiClient.post<dynamic>(
        ApiConstants.pagosEndpoint,
        data: construirFormData(params),
      );
      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final pagoData = rawData['data'] is Map<String, dynamic>
            ? rawData['data'] as Map<String, dynamic>
            : rawData;
        return PagoModel.fromJson(pagoData);
      }
      throw const ServerException(message: 'Formato de respuesta inválido al registrar pago');
    } on DioException catch (e) {
      // Errores de negocio (400, 403, 409, 413, 422): solo se conserva el mensaje
      // del backend (puede ir vacío) para que la presentación decida qué mostrar.
      final statusCode = e.response?.statusCode;
      if (statusCode != null &&
          statusCode >= 400 &&
          statusCode < 500 &&
          statusCode != 401 &&
          statusCode != 404) {
        throw ServerException(
          message: NetworkErrorHandler.extractErrorMessage(e) ?? '',
          statusCode: statusCode,
        );
      }
      NetworkErrorHandler.handleDioException(e, fallbackMessage: 'Error al registrar pago');
    }
  }

  @override
  Future<PagoModel> obtenerPago(int idPayment) async {
    try {
      final response = await apiClient.get<dynamic>('${ApiConstants.pagosEndpoint}/$idPayment');
      return _leerPago(response.data);
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(e, fallbackMessage: 'Error al consultar el pago');
    }
  }

  @override
  Future<PagoModel> confirmarPago(int idPayment) async {
    try {
      final response = await apiClient.patch<dynamic>('${ApiConstants.pagosEndpoint}/$idPayment/confirmar');
      return _leerPago(response.data);
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(e, fallbackMessage: 'Error al confirmar el pago');
    }
  }

  @override
  Future<PagoModel> rechazarPago(int idPayment, String motivo) async {
    try {
      final response = await apiClient.patch<dynamic>(
        '${ApiConstants.pagosEndpoint}/$idPayment/rechazar',
        data: <String, dynamic>{'motivo': motivo},
      );
      return _leerPago(response.data);
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(e, fallbackMessage: 'Error al rechazar el pago');
    }
  }

  static PagoModel _leerPago(dynamic rawData) {
    if (rawData is Map<String, dynamic>) {
      final pagoData = rawData['data'] is Map<String, dynamic>
          ? rawData['data'] as Map<String, dynamic>
          : rawData;
      return PagoModel.fromJson(pagoData);
    }
    throw const ServerException(message: 'Formato de pago inválido');
  }
}
