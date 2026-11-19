import 'package:equatable/equatable.dart';
import 'package:tandea/core/utils/formato_moneda.dart';
import 'package:tandea/features/admin/domain/entities/admin_disputa_entity.dart';
import 'package:tandea/features/entregas/domain/entities/entrega_entity.dart';
import 'package:tandea/features/pagos/domain/entities/pago_entity.dart';

/// Entrada de la bitácora inmutable de auditoría (`audit_log`) asociada al caso.
class BitacoraEntradaEntity extends Equatable {
  final int idLog;
  final int? idUser;
  final String actionType;
  final String entityType;
  final int? entityId;
  final String description;
  final DateTime? createdAt;

  const BitacoraEntradaEntity({
    required this.idLog,
    this.idUser,
    required this.actionType,
    required this.entityType,
    this.entityId,
    required this.description,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        idLog,
        idUser,
        actionType,
        entityType,
        entityId,
        description,
        createdAt,
      ];
}

/// Categoría del evento en la línea de tiempo de una disputa.
enum TipoEventoCaso {
  pagoEntrega,
  confirmacion,
  evidencia,
  reporte,
  auditoria,
  resolucion;

  String get etiqueta {
    switch (this) {
      case TipoEventoCaso.pagoEntrega:
        return 'Pago / Entrega';
      case TipoEventoCaso.confirmacion:
        return 'Confirmación';
      case TipoEventoCaso.evidencia:
        return 'Evidencia';
      case TipoEventoCaso.reporte:
        return 'Reporte';
      case TipoEventoCaso.auditoria:
        return 'Bitácora';
      case TipoEventoCaso.resolucion:
        return 'Resolución';
    }
  }
}

/// Evento individual dentro de la línea de tiempo cronológica del caso.
class EventoLineaTiempoCaso extends Equatable {
  final TipoEventoCaso tipo;
  final String titulo;
  final String descripcion;
  final DateTime? fecha;
  final String? evidenceUrl;
  final String? badge;

  const EventoLineaTiempoCaso({
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    this.fecha,
    this.evidenceUrl,
    this.badge,
  });

  @override
  List<Object?> get props => [
        tipo,
        titulo,
        descripcion,
        fecha,
        evidenceUrl,
        badge,
      ];
}

/// Entidad que consolida el detalle completo de una disputa, su pago/entrega,
/// bitácora de auditoría y la línea de tiempo ordenada cronológicamente.
class AdminDisputaDetalleEntity extends Equatable {
  final AdminDisputaEntity disputa;
  final List<BitacoraEntradaEntity> bitacora;
  final PagoEntity? pago;
  final EntregaEntity? entrega;
  final List<EventoLineaTiempoCaso> _lineaTiempoPersonalizada;

  const AdminDisputaDetalleEntity({
    required this.disputa,
    this.bitacora = const [],
    this.pago,
    this.entrega,
    List<EventoLineaTiempoCaso> lineaTiempo = const [],
  }) : _lineaTiempoPersonalizada = lineaTiempo;

  /// Construye o retorna la línea de tiempo ordenada cronológicamente con:
  /// 1. Pagos / Entregas
  /// 2. Confirmaciones (participante, organizador/admin, verificación OCR)
  /// 3. Evidencias (`evidenceUrl`)
  /// 4. Reporte, Bitácora (`audit_log`) y Resolución.
  List<EventoLineaTiempoCaso> get lineaTiempo {
    if (_lineaTiempoPersonalizada.isNotEmpty) {
      return _lineaTiempoPersonalizada;
    }

    final eventos = <EventoLineaTiempoCaso>[];
    final baseTime =
        pago?.createdAt ?? disputa.createdAt ?? DateTime(2026, 11, 1, 10, 0);

    // 1. Eventos de Pago (si la disputa está vinculada a un idPayment)
    if (pago != null) {
      final p = pago!;
      final fechaPago = p.createdAt ?? baseTime;
      eventos.add(
        EventoLineaTiempoCaso(
          tipo: TipoEventoCaso.pagoEntrega,
          titulo: 'Pago registrado (#${p.idPayment})',
          descripcion:
              'Monto total: ${formatearMonedaMxn(p.totalAmount)} '
              '(Transferencia: ${formatearMonedaMxn(p.transferAmount)}, '
              'Efectivo: ${formatearMonedaMxn(p.cashAmount)}) • '
              'Método: ${p.metodoPago.etiqueta}',
          fecha: fechaPago,
          badge: p.status,
        ),
      );

      // 2. Confirmaciones del pago
      final partesConfirmacion = <String>[
        p.confirmedByParticipant
            ? 'Confirmado por participante'
            : 'Pendiente de participante',
        p.confirmedByAdmin
            ? 'Confirmado por organizador'
            : (p.estaRechazado
                ? 'Rechazado por organizador'
                : 'Pendiente de organizador'),
        if (p.ocrVerified)
          'OCR verificado${p.ocrDetectedAmount != null ? ' (${formatearMonedaMxn(p.ocrDetectedAmount!)})' : ''}'
        else
          'OCR sin verificar',
      ];
      if (p.rejectionReason != null && p.rejectionReason!.trim().isNotEmpty) {
        partesConfirmacion.add('Motivo rechazo: ${p.rejectionReason}');
      }

      eventos.add(
        EventoLineaTiempoCaso(
          tipo: TipoEventoCaso.confirmacion,
          titulo: 'Confirmaciones y validación del pago',
          descripcion: partesConfirmacion.join(' • '),
          fecha: fechaPago.add(const Duration(seconds: 1)),
          badge: p.confirmedByAdmin
              ? 'CONFIRMADO'
              : (p.estaRechazado ? 'RECHAZADO' : 'EN VALIDACIÓN'),
        ),
      );

      // 3. Evidencia adjunta del pago
      if (p.evidenceUrl != null && p.evidenceUrl!.trim().isNotEmpty) {
        eventos.add(
          EventoLineaTiempoCaso(
            tipo: TipoEventoCaso.evidencia,
            titulo: 'Comprobante de pago adjunto',
            descripcion: 'Evidencia digital registrada para el pago #${p.idPayment}',
            fecha: fechaPago.add(const Duration(seconds: 2)),
            evidenceUrl: p.evidenceUrl,
            badge: 'EVIDENCIA',
          ),
        );
      }
    }

    // 1b. Eventos de Entrega (si la disputa está vinculada a un idPayout)
    if (entrega != null) {
      final e = entrega!;
      final fechaEntrega = baseTime;
      eventos.add(
        EventoLineaTiempoCaso(
          tipo: TipoEventoCaso.pagoEntrega,
          titulo: 'Entrega registrada (#${e.idPayout} • Turno ${e.numero})',
          descripcion:
              'Total entregado: ${formatearMonedaMxn(e.total)} '
              '(Transferencia: ${formatearMonedaMxn(e.transferencia)}, '
              'Efectivo: ${formatearMonedaMxn(e.efectivo)})',
          fecha: fechaEntrega,
          badge: e.confirmada ? 'CONFIRMADO' : 'PENDIENTE',
        ),
      );

      eventos.add(
        EventoLineaTiempoCaso(
          tipo: TipoEventoCaso.confirmacion,
          titulo: 'Estado de confirmación de entrega',
          descripcion: e.confirmada
              ? 'Entrega confirmada por el beneficiario del turno ${e.numero}'
              : 'Entrega pendiente de confirmación por el beneficiario',
          fecha: fechaEntrega.add(const Duration(seconds: 1)),
          badge: e.confirmada ? 'CONFIRMADA' : 'PENDIENTE',
        ),
      );

      if (e.evidenciaUrl != null && e.evidenciaUrl!.trim().isNotEmpty) {
        eventos.add(
          EventoLineaTiempoCaso(
            tipo: TipoEventoCaso.evidencia,
            titulo: 'Comprobante de entrega adjunto',
            descripcion:
                'Evidencia digital registrada para la entrega #${e.idPayout}',
            fecha: fechaEntrega.add(const Duration(seconds: 2)),
            evidenceUrl: e.evidenciaUrl,
            badge: 'EVIDENCIA',
          ),
        );
      }
    }

    // 4. Apertura del reporte de disputa
    final fechaReporte =
        disputa.createdAt ?? baseTime.add(const Duration(minutes: 5));
    eventos.add(
      EventoLineaTiempoCaso(
        tipo: TipoEventoCaso.reporte,
        titulo: 'Caso reportado (#${disputa.idDispute})',
        descripcion:
            'Reportado por ${disputa.nombreReporter} (${disputa.emailReporter}): ${disputa.reason}',
        fecha: fechaReporte,
        badge: disputa.status,
      ),
    );

    // 5. Entradas de bitácora (audit_log)
    for (var i = 0; i < bitacora.length; i++) {
      final log = bitacora[i];
      eventos.add(
        EventoLineaTiempoCaso(
          tipo: TipoEventoCaso.auditoria,
          titulo: 'Bitácora: ${log.actionType}',
          descripcion: log.description,
          fecha: log.createdAt ??
              fechaReporte.add(Duration(minutes: i + 1)),
          badge: log.entityType,
        ),
      );
    }

    // 6. Resolución del caso (si ya fue resuelto)
    if (disputa.estaResuelta &&
        disputa.resolutionNotes != null &&
        disputa.resolutionNotes!.trim().isNotEmpty) {
      eventos.add(
        EventoLineaTiempoCaso(
          tipo: TipoEventoCaso.resolucion,
          titulo: 'Caso resuelto por Administrador Global',
          descripcion: 'Notas de resolución: ${disputa.resolutionNotes}',
          fecha: disputa.resolvedAt ??
              disputa.updatedAt ??
              fechaReporte.add(const Duration(hours: 1)),
          badge: 'RESUELTA',
        ),
      );
    }

    // Ordenar cronológicamente de más antiguo a más reciente
    eventos.sort((a, b) {
      final fa = a.fecha;
      final fb = b.fecha;
      if (fa == null && fb == null) return 0;
      if (fa == null) return -1;
      if (fb == null) return 1;
      return fa.compareTo(fb);
    });

    return eventos;
  }

  AdminDisputaDetalleEntity copyWith({
    AdminDisputaEntity? disputa,
    List<BitacoraEntradaEntity>? bitacora,
    PagoEntity? pago,
    EntregaEntity? entrega,
    List<EventoLineaTiempoCaso>? lineaTiempo,
  }) {
    return AdminDisputaDetalleEntity(
      disputa: disputa ?? this.disputa,
      bitacora: bitacora ?? this.bitacora,
      pago: pago ?? this.pago,
      entrega: entrega ?? this.entrega,
      lineaTiempo: lineaTiempo ?? _lineaTiempoPersonalizada,
    );
  }

  @override
  List<Object?> get props => [
        disputa,
        bitacora,
        pago,
        entrega,
        _lineaTiempoPersonalizada,
      ];
}
