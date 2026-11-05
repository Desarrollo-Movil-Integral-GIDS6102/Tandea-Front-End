import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/core/utils/formato_moneda.dart';
import 'package:tandea/features/entregas/presentation/screens/registrar_entrega_screen.dart';
import 'package:tandea/features/pagos/presentation/screens/registrar_pago_screen.dart';
import 'package:tandea/features/tandas/domain/entities/calendario_tanda.dart';
import 'package:tandea/features/tandas/domain/entities/numero_tanda.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/presentation/providers/tanda_detalle_provider.dart';

/// Detalle de una tanda para participantes y organizador (AP-06).
///
/// Incluye tarjeta de progreso, número asignado al usuario y calendario de turnos
/// (`table_calendar`) con marcadores de fechas de pago y cobro.
class TandaDetalleScreen extends StatelessWidget {
  final String idTanda;

  const TandaDetalleScreen({super.key, required this.idTanda});

  Future<void> _recargar(BuildContext context) =>
      context.read<TandaDetalleProvider>().cargar(idTanda);

  Future<void> _apartarNumeros(BuildContext context, TandaEntity tanda) async {
    await context.push(RouteNames.seleccionarNumero, extra: tanda);
    if (context.mounted) await _recargar(context);
  }

  Future<void> _pagar(BuildContext context, TandaEntity tanda, NumeroTanda numero) async {
    await context.push(
      RouteNames.registrarPago,
      extra: RegistrarPagoArgs(
        nombreTanda: tanda.nombre,
        idNumber: numero.idNumber,
        cuota: tanda.monto,
        numeroTurno: numero.numberValue,
        vuelta: numero.roundNumber,
      ),
    );
    if (context.mounted) await _recargar(context);
  }

  Future<void> _confirmarRecepcion(BuildContext context, NumeroTanda numero) async {
    await context.push(RouteNames.entregaDetalle(numero.idPayout!));
    if (context.mounted) await _recargar(context);
  }

  Future<void> _registrarEntrega(BuildContext context, TandaEntity tanda, NumeroTanda numero) async {
    await context.push(
      RouteNames.registrarEntrega,
      extra: RegistrarEntregaArgs(
        idNumber: numero.idNumber,
        numero: numero.numberValue,
        nombreReceptor: numero.userName ?? 'Participante',
        total: tanda.monto * tanda.totalParticipantes,
      ),
    );
    if (context.mounted) await _recargar(context);
  }

  Future<void> _iniciar(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Iniciar la tanda?'),
        content: const Text(
          'Ya no se podrán apartar números y los participantes podrán empezar a pagar.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            key: const Key('btn_confirmar_iniciar_tanda'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    await context.read<TandaDetalleProvider>().iniciar();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TandaDetalleProvider>();
    final tanda = provider.tanda;
    final calendario = provider.calendario;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(tanda?.nombre ?? 'Detalle de la tanda'),
        actions: [
          if (tanda != null && tanda.esOrganizador && (tanda.inviteCode?.isNotEmpty ?? false))
            IconButton(
              key: const Key('btn_detalle_compartir'),
              tooltip: 'Compartir código',
              icon: const Icon(Icons.share_rounded),
              onPressed: () => context.push(RouteNames.compartirCodigo, extra: tanda),
            ),
        ],
      ),
      body: SafeArea(
        child: tanda == null
            ? Center(
                child: provider.cargando
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              provider.errorMessage ?? 'No se pudo cargar la tanda.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _recargar(context),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
              )
            : RefreshIndicator(
                onRefresh: () => _recargar(context),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _Resumen(tanda: tanda),
                    const SizedBox(height: 16),
                    _TarjetaProgresoYNumero(
                      tanda: tanda,
                      calendario: calendario,
                    ),
                    const SizedBox(height: 16),
                    _AvisoEstado(tanda: tanda),
                    if (provider.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        provider.errorMessage!,
                        key: const Key('detalle_error'),
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (calendario != null && calendario.turnos.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _CalendarioTurnosCard(
                        tanda: tanda,
                        calendario: calendario,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _MisNumeros(
                      tanda: tanda,
                      onPagar: (n) => _pagar(context, tanda, n),
                      onConfirmarRecepcion: (n) => _confirmarRecepcion(context, n),
                    ),
                    if (tanda.aceptaNumeros) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('btn_apartar_numeros'),
                        onPressed: () => _apartarNumeros(context, tanda),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: Text(
                          tanda.misNumeros.isEmpty ? 'Apartar mis números' : 'Apartar más números',
                        ),
                      ),
                    ],
                    if (tanda.esOrganizador && tanda.esPendiente) ...[
                      const SizedBox(height: 12),
                      _BotonIniciar(
                        tanda: tanda,
                        iniciando: provider.iniciando,
                        onIniciar: () => _iniciar(context),
                      ),
                    ],
                    if (tanda.esOrganizador && tanda.esActiva) ...[
                      const SizedBox(height: 12),
                      _TurnoVigente(
                        tanda: tanda,
                        onRegistrar: (n) => _registrarEntrega(context, tanda, n),
                      ),
                    ],
                    if (tanda.esOrganizador) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('btn_ver_seguimiento'),
                        onPressed: () async {
                          await context.push(RouteNames.seguimientoTandaDe(tanda.id), extra: tanda);
                          if (context.mounted) await _recargar(context);
                        },
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Ver quién ha pagado'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('btn_ver_historial'),
                      onPressed: () => context.push(RouteNames.historialTandaDe(tanda.id), extra: tanda),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Ver historial de pagos y cobros'),
                    ),
                    const SizedBox(height: 24),
                    _TablaNumeros(tanda: tanda),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Tarjeta que muestra el progreso de la tanda y el número asignado al usuario (AP-06).
class _TarjetaProgresoYNumero extends StatelessWidget {
  final TandaEntity tanda;
  final CalendarioTanda? calendario;

  const _TarjetaProgresoYNumero({
    required this.tanda,
    required this.calendario,
  });

  @override
  Widget build(BuildContext context) {
    final numerosUsuario = <int>[
      for (final n in tanda.misNumeros) n.numberValue,
      if (tanda.misNumeros.isEmpty && tanda.numeroTurnoUsuario != null)
        tanda.numeroTurnoUsuario!,
    ];
    final etiquetaNumero = numerosUsuario.isEmpty
        ? 'Sin asignar'
        : numerosUsuario.map((n) => '#$n').join(', ');

    final totalTurnos = tanda.totalParticipantes > 0 ? tanda.totalParticipantes : 1;
    final completados = tanda.numeros
        .where((n) => !n.isDeadNumber && (n.entregado || n.pagoConfirmado))
        .length
        .clamp(0, totalTurnos);
    final progreso = totalTurnos > 0 ? completados / totalTurnos : 0.0;
    final porcentaje = (progreso * 100).round();

    // Buscar próxima fecha de cobro del usuario en el calendario
    TurnoCalendario? proximoCobroUsuario;
    if (calendario != null && numerosUsuario.isNotEmpty) {
      for (final t in calendario!.turnos) {
        if (numerosUsuario.contains(t.numero)) {
          proximoCobroUsuario = t;
          break;
        }
      }
    }

    return Card(
      key: const Key('tarjeta_progreso_tanda'),
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Número asignado: $etiquetaNumero',
                        key: const Key('numero_asignado_usuario'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '$porcentaje%',
                  key: const Key('porcentaje_progreso_tanda'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (proximoCobroUsuario != null) ...[
              const SizedBox(height: 10),
              Text(
                'Tu fecha de cobro: ${proximoCobroUsuario.fechaCobro} (${formatearMonedaMxn(proximoCobroUsuario.montoAEsperar)})',
                key: const Key('fecha_cobro_usuario'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                key: const Key('barra_progreso_tanda'),
                value: progreso,
                minHeight: 8,
                backgroundColor: AppColors.border,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Progreso de la tanda: $completados de $totalTurnos turnos completados',
              key: const Key('texto_progreso_tanda'),
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Calendario interactivo (`table_calendar`) con marcadores de fechas de pago y cobro (AP-06).
class _CalendarioTurnosCard extends StatefulWidget {
  final TandaEntity tanda;
  final CalendarioTanda calendario;

  const _CalendarioTurnosCard({
    required this.tanda,
    required this.calendario,
  });

  @override
  State<_CalendarioTurnosCard> createState() => _CalendarioTurnosCardState();
}

class _CalendarioTurnosCardState extends State<_CalendarioTurnosCard> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final primerFecha = widget.calendario.turnos
        .map((t) => t.fechaDate)
        .whereType<DateTime>()
        .firstOrNull;
    _focusedDay = primerFecha ?? DateTime.utc(2026, 1, 1);
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final fechas = widget.calendario.turnos
        .map((t) => t.fechaDate)
        .whereType<DateTime>()
        .toList();

    final firstDay = fechas.isNotEmpty
        ? DateTime.utc(fechas.first.year - 1, 1, 1)
        : DateTime.utc(2024, 1, 1);
    final lastDay = fechas.isNotEmpty
        ? DateTime.utc(fechas.last.year + 1, 12, 31)
        : DateTime.utc(2030, 12, 31);

    final focused = _focusedDay.isBefore(firstDay)
        ? firstDay
        : (_focusedDay.isAfter(lastDay) ? lastDay : _focusedDay);

    final misNumerosSet = <int>{
      for (final n in widget.tanda.misNumeros) n.numberValue,
      if (widget.tanda.numeroTurnoUsuario != null) widget.tanda.numeroTurnoUsuario!,
    };

    final turnosDiaSeleccionado = _selectedDay != null
        ? widget.calendario.turnosEnDia(_selectedDay!)
        : const <TurnoCalendario>[];

    return Card(
      key: const Key('calendario_turnos_tanda'),
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Calendario de turnos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _LeyendaMarcador(
                  key: Key('leyenda_fecha_pago'),
                  color: AppColors.primary,
                  etiqueta: 'Fecha de pago',
                ),
                _LeyendaMarcador(
                  key: Key('leyenda_fecha_cobro'),
                  color: AppColors.secondary,
                  etiqueta: 'Fecha de cobro',
                ),
              ],
            ),
            const SizedBox(height: 8),
            TableCalendar<TurnoCalendario>(
              firstDay: firstDay,
              lastDay: lastDay,
              focusedDay: focused,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mes',
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              eventLoader: (day) => widget.calendario.turnosEnDia(day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarBuilders: CalendarBuilders<TurnoCalendario>(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  final turno = events.first;
                  final esMiCobro = misNumerosSet.contains(turno.numero);
                  return Positioned(
                    bottom: 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          key: Key('marcador_pago_${turno.fechaCobro}'),
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!turno.esNumeroMuerto)
                          Container(
                            key: Key('marcador_cobro_${turno.fechaCobro}'),
                            width: esMiCobro ? 9 : 7,
                            height: esMiCobro ? 9 : 7,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: esMiCobro ? AppColors.success : AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (turnosDiaSeleccionado.isNotEmpty) ...[
              const Divider(height: 20),
              for (final t in turnosDiaSeleccionado)
                Container(
                  key: Key('detalle_turno_${t.numero}'),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: t.esNumeroMuerto ? AppColors.textSecondaryLight : AppColors.primary,
                        child: Text(
                          '#${t.numero}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.esNumeroMuerto
                                  ? 'Turno #${t.turno}: Número muerto (caja)'
                                  : 'Turno #${t.turno} • Cobra #${t.numero}${t.nombreUsuario != null ? ' (${t.nombreUsuario})' : ''}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Fecha: ${t.fechaCobro} • Monto: ${formatearMonedaMxn(t.montoAEsperar)}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeyendaMarcador extends StatelessWidget {
  final Color color;
  final String etiqueta;

  const _LeyendaMarcador({
    super.key,
    required this.color,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          etiqueta,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }
}

class _Resumen extends StatelessWidget {
  final TandaEntity tanda;

  const _Resumen({required this.tanda});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tanda.inviteCode ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Chip(
                  key: const Key('detalle_estado'),
                  label: Text(tanda.estado.toUpperCase()),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 24),
            _Fila('Cuota por número', formatearMonedaMxn(tanda.monto)),
            _Fila('Periodicidad', tanda.periodo.toUpperCase()),
            _Fila('Números', '${tanda.totalParticipantes}'),
            _Fila('Cobro por turno', formatearMonedaMxn(tanda.monto * tanda.totalParticipantes)),
            if (tanda.startDate != null) _Fila('Inicio', tanda.startDate!.split('T').first),
            if (tanda.endDate != null) _Fila('Último turno', tanda.endDate!.split('T').first),
          ],
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String label;
  final String valor;

  const _Fila(this.label, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondaryLight)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AvisoEstado extends StatelessWidget {
  final TandaEntity tanda;

  const _AvisoEstado({required this.tanda});

  @override
  Widget build(BuildContext context) {
    final String texto;
    if (tanda.esActiva) {
      texto = 'La tanda está en curso. Ya puedes registrar los pagos de tus números.';
    } else if (tanda.esPendiente) {
      final libres = tanda.numerosDisponibles?.length ?? 0;
      texto = 'La tanda aún no inicia${libres > 0 ? ' (quedan $libres números libres)' : ''}. '
          'Los pagos se habilitan cuando el organizador la inicie.';
    } else {
      texto = 'Esta tanda está ${tanda.estado.toLowerCase()}.';
    }

    return Container(
      key: const Key('detalle_aviso_estado'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}

class _MisNumeros extends StatelessWidget {
  final TandaEntity tanda;
  final ValueChanged<NumeroTanda> onPagar;
  final ValueChanged<NumeroTanda> onConfirmarRecepcion;

  const _MisNumeros({
    required this.tanda,
    required this.onPagar,
    required this.onConfirmarRecepcion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Mis números',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (tanda.misNumeros.isEmpty)
          const Text(
            'Aún no tienes números en esta tanda.',
            style: TextStyle(color: AppColors.textSecondaryLight),
          )
        else
          for (final n in tanda.misNumeros)
            Card(
              key: Key('mi_numero_${n.numberValue}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        '${n.numberValue}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text('Número #${n.numberValue}'),
                    subtitle: Text(
                      n.pagoEnRevision
                          ? 'Ya pagaste. Tu pago está siendo analizado por el organizador.'
                          : n.pagoConfirmado
                              ? 'El organizador confirmó tu pago.'
                              : 'Vuelta ${n.roundNumber}',
                    ),
                    trailing: n.estadoPago != null
                        ? Chip(
                            key: Key('estado_pago_numero_${n.numberValue}'),
                            label: Text(n.pagoConfirmado ? 'Pagado' : 'En revisión'),
                            visualDensity: VisualDensity.compact,
                          )
                        : ElevatedButton(
                            key: Key('btn_pagar_numero_${n.numberValue}'),
                            // Pagar solo cuando el organizador ya inició la tanda
                            onPressed: tanda.esActiva ? () => onPagar(n) : null,
                            child: const Text('Pagar'),
                          ),
                  ),
                  if (n.entregaPorConfirmar && n.idPayout != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: ElevatedButton(
                        key: Key('btn_confirmar_recepcion_${n.numberValue}'),
                        onPressed: () => onConfirmarRecepcion(n),
                        child: const Text('El organizador te entregó el dinero: confirmar'),
                      ),
                    ),
                  if (n.entregado)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text('Turno cobrado.', style: TextStyle(color: AppColors.success)),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

/// Muestra al organizador a quién le toca cobrar y le permite registrar la entrega.
class _TurnoVigente extends StatelessWidget {
  final TandaEntity tanda;
  final ValueChanged<NumeroTanda> onRegistrar;

  const _TurnoVigente({required this.tanda, required this.onRegistrar});

  @override
  Widget build(BuildContext context) {
    final abiertos = tanda.numeros.where((n) => !n.isDeadNumber && !n.entregado).toList()
      ..sort((a, b) => a.numberValue.compareTo(b.numberValue));
    if (abiertos.isEmpty) return const SizedBox.shrink();
    final turno = abiertos.first;

    if (turno.entregaPorConfirmar) {
      return Text(
        'Entrega del número #${turno.numberValue} registrada. Falta que la confirme.',
        key: const Key('turno_esperando_confirmacion'),
        style: const TextStyle(color: AppColors.textSecondaryLight),
      );
    }
    return ElevatedButton.icon(
      key: const Key('btn_registrar_entrega'),
      onPressed: () => onRegistrar(turno),
      icon: const Icon(Icons.payments_outlined),
      label: Text('Registrar entrega del turno #${turno.numberValue}'),
    );
  }
}

class _BotonIniciar extends StatelessWidget {
  final TandaEntity tanda;
  final bool iniciando;
  final VoidCallback onIniciar;

  const _BotonIniciar({required this.tanda, required this.iniciando, required this.onIniciar});

  @override
  Widget build(BuildContext context) {
    final faltan = tanda.numerosDisponibles?.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          key: const Key('btn_iniciar_tanda'),
          onPressed: faltan == 0 && !iniciando ? onIniciar : null,
          icon: iniciando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow_rounded),
          label: const Text('Iniciar tanda'),
        ),
        if (faltan > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Faltan $faltan números por apartar para poder iniciar.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
            ),
          ),
      ],
    );
  }
}

class _TablaNumeros extends StatelessWidget {
  final TandaEntity tanda;

  const _TablaNumeros({required this.tanda});

  @override
  Widget build(BuildContext context) {
    final porNumero = {
      for (final n in tanda.numeros.where((n) => n.roundNumber == 1)) n.numberValue: n,
    };
    // El número muerto siempre es el #0; los participantes van de #1 a #N
    final primero = tanda.hasDeadNumber == true ? 0 : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Números de la tanda',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (var valor = primero; valor <= tanda.totalParticipantes; valor++)
          ListTile(
            key: Key('fila_numero_$valor'),
            dense: true,
            leading: Text('#$valor', style: const TextStyle(fontWeight: FontWeight.bold)),
            title: Text(switch (porNumero[valor]) {
              _ when valor == 0 => 'Número muerto (caja)',
              null => 'Disponible',
              final n => n.userName ?? 'Apartado',
            }),
            trailing: switch (porNumero[valor]) {
              final n? when n.pagoConfirmado => const Text('Pagado'),
              final n? when n.pagoEnRevision => const Text('En revisión'),
              _ => null,
            },
          ),
      ],
    );
  }
}
