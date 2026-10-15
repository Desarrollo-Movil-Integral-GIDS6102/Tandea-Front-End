import 'package:dio/dio.dart';
import 'package:tandea/core/constants/api_constants.dart';
import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/network/api_client.dart';
import 'package:tandea/core/network/network_error_handler.dart';
import 'package:tandea/features/pagos/data/models/pago_model.dart';

abstract class PagoRemoteDataSource {
  Future<List<PagoModel>> getPagosByTanda(String tandaId);

  Future<PagoModel> registrarPago({
    required String tandaId,
    required double monto,
    String? comprobanteUrl,
  });
}

class PagoRemoteDataSourceImpl implements PagoRemoteDataSource {
  final ApiClient _apiClient;

  PagoRemoteDataSourceImpl({required this._apiClient});

  @override
  Future<List<PagoModel>> getPagosByTanda(String tandaId) async {
    try {
      final response = await _apiClient.get<dynamic>(
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

  @override
  Future<PagoModel> registrarPago({
    required String tandaId,
    required double monto,
    String? comprobanteUrl,
  }) async {
    try {
      final response = await _apiClient.post<dynamic>(
        ApiConstants.pagosEndpoint,
        data: <String, dynamic>{
          'tandaId': tandaId,
          'monto': monto,
          'comprobanteUrl': ?comprobanteUrl,
        },
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
      NetworkErrorHandler.handleDioException(e, fallbackMessage: 'Error al registrar pago');
    }
  }
}
