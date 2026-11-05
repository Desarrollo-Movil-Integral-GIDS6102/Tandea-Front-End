import 'package:tandea/features/tandas/domain/entities/movimiento_historial.dart';

/// DTO de `GET /tandas/:id/historial` (`data: { items, nextCursor }`).
class HistorialTandaModel extends PaginaHistorial {
  const HistorialTandaModel({required super.items, super.nextCursor});

  static double _toDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static MovimientoHistorial movimientoFromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'];
    final fecha = json['fecha'] ?? json['createdAt'];
    return MovimientoHistorial(
      tipo: TipoMovimiento.fromValor(json['tipo']?.toString()),
      id: _toInt(json['id']),
      numero: _toInt(json['numero'] ?? json['numberValue']),
      nombre: usuario is Map<String, dynamic> ? usuario['nombre']?.toString() : null,
      monto: _toDouble(json['monto'] ?? json['totalAmount']),
      transferAmount: _toDouble(json['transferAmount']),
      cashAmount: _toDouble(json['cashAmount']),
      estado: (json['estado'] ?? json['status'] ?? 'PENDIENTE').toString(),
      fecha: fecha == null ? null : DateTime.tryParse(fecha.toString()),
    );
  }

  factory HistorialTandaModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final cursor = json['nextCursor']?.toString();
    return HistorialTandaModel(
      items: (rawItems is List<dynamic> ? rawItems : const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(movimientoFromJson)
          .toList(),
      nextCursor: (cursor == null || cursor.isEmpty) ? null : cursor,
    );
  }
}
