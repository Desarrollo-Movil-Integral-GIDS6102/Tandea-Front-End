import 'package:dio/dio.dart';
import 'package:tandea/core/constants/api_constants.dart';
import 'package:tandea/core/errors/exceptions.dart';
import 'package:tandea/core/network/api_client.dart';
import 'package:tandea/core/network/network_error_handler.dart';
import 'package:tandea/features/admin/data/models/admin_metricas_model.dart';

abstract class AdminRemoteDataSource {
  Future<AdminMetricasModel> obtenerMetricas();
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final ApiClient apiClient;

  AdminRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AdminMetricasModel> obtenerMetricas() async {
    try {
      final response = await apiClient.get<dynamic>(
        ApiConstants.adminMetricasEndpoint,
      );
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        return AdminMetricasModel.fromJson(raw);
      }
      throw const ServerException(
        message: 'Formato de respuesta inválido al consultar métricas.',
      );
    } on DioException catch (e) {
      NetworkErrorHandler.handleDioException(
        e,
        fallbackMessage: 'Error al obtener las métricas globales',
      );
    }
  }
}
