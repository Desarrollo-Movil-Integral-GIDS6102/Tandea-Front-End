import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/entities/unirse_tanda_result.dart';
import 'package:tandea/features/tandas/presentation/providers/unirse_tanda_provider.dart';

/// Pantalla para apartar uno o varios números (turnos de cobro) de una tanda.
/// Muestra #1..#N; los ocupados se ven distintos y no se pueden seleccionar.
class SeleccionarNumeroScreen extends StatefulWidget {
  final TandaEntity tanda;

  const SeleccionarNumeroScreen({
    super.key,
    required this.tanda,
  });

  @override
  State<SeleccionarNumeroScreen> createState() => _SeleccionarNumeroScreenState();
}

class _SeleccionarNumeroScreenState extends State<SeleccionarNumeroScreen> {
  final Set<int> _seleccionados = {};
  late TandaEntity _tanda = widget.tanda;

  Set<int> get _libres =>
      (_tanda.numerosDisponibles ??
              List<int>.generate(_tanda.totalParticipantes, (i) => i + 1))
          .toSet();

  /// Consulta la disponibilidad actual para no mostrar datos viejos.
  Future<void> _refrescarDisponibles() async {
    final tanda = await context.read<UnirseTandaProvider>().refrescarTanda();
    if (tanda == null || !mounted) return;
    setState(() {
      _tanda = tanda;
      _seleccionados.retainAll(_libres);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<UnirseTandaProvider>();
      // Al llegar desde el detalle (organizador) no hubo búsqueda por código
      final code = widget.tanda.inviteCode;
      if (code != null && code.isNotEmpty) {
        provider.setInviteCode(code);
      }
      provider.clearErrors();
      _refrescarDisponibles();
    });
  }

  Future<void> _handleConfirmarNumero() async {
    if (_seleccionados.isEmpty) return;

    final provider = context.read<UnirseTandaProvider>();
    final resultado = await provider.unirse(
      selectedNumbers: _seleccionados.toList()..sort(),
    );

    if (!mounted) return;
    if (resultado == null) {
      // Alguien tomó un número mientras tanto: el banner muestra cuál y la cuadrícula se actualiza
      await _refrescarDisponibles();
      return;
    }

    _mostrarDialogoExito(resultado);
  }

  void _mostrarDialogoExito(UnirseTandaResult result) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: AppColors.accent, size: 30),
            SizedBox(width: 10),
            Text('¡Turno Reservado!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apartaste ${result.numerosAsignados.length == 1 ? 'tu número' : 'tus números'} en "${result.tanda.nombre}".',
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    result.numerosAsignados.length == 1 ? 'Tu número: ' : 'Tus números: ',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  Text(
                    result.numerosAsignados.map((n) => '#$n').join(', '),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            key: const Key('btn_exito_selector_ir_tandas'),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.go(RouteNames.tandaDetalle(widget.tanda.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ver detalle de la tanda'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<UnirseTandaProvider>();
    final isLoading = provider.isLoading;
    final totalNumeros = _tanda.totalParticipantes;
    final montoTotalCobro = _tanda.monto * totalNumeros;
    final libres = _libres;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Elegir Turno'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjeta resumen de la tanda
                Card(
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.06),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  color: AppColors.surfaceLight,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.format_list_numbered_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _tanda.nombre,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _tanda.periodo.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondaryLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoCol('Aportación', '\$${_tanda.monto.toStringAsFixed(2)}'),
                            _buildInfoCol('Total a recibir', '\$${montoTotalCobro.toStringAsFixed(2)}', isHighlight: true),
                            _buildInfoCol('Cupo', '$totalNumeros turnos'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Mensaje de error retornado por el backend
                if (provider.backendError != null) ...[
                  _buildErrorBanner(provider.backendError!),
                  const SizedBox(height: 16),
                ],

                // Instrucción
                Text(
                  'Elige uno o varios números para cobrar:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Quedan ${libres.length} de $totalNumeros números libres. Puedes apartar más de uno.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 16),

                // Cuadrícula de números
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalNumeros,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    final numero = index + 1;
                    final isSelected = _seleccionados.contains(numero);
                    final ocupado = !libres.contains(numero);

                    return InkWell(
                      key: Key('btn_seleccionar_numero_$numero'),
                      onTap: isLoading || ocupado
                          ? null
                          : () {
                              setState(() {
                                isSelected
                                    ? _seleccionados.remove(numero)
                                    : _seleccionados.add(numero);
                              });
                              provider.clearErrors();
                            },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : ocupado
                                  ? Colors.grey.shade200
                                  : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.grey.shade300,
                            width: isSelected ? 2.5 : 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '#$numero',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : ocupado
                                        ? Colors.grey.shade500
                                        : AppColors.textPrimaryLight,
                                decoration: ocupado ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (ocupado)
                              Text(
                                'Ocupado',
                                key: Key('etiqueta_ocupado_$numero'),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            if (isSelected) ...[
                              const SizedBox(height: 2),
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Botón de Confirmación
                ElevatedButton(
                  key: const Key('btn_confirmar_turno'),
                  onPressed: (_seleccionados.isEmpty || isLoading)
                      ? null
                      : _handleConfirmarNumero,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _seleccionados.isEmpty
                              ? 'Selecciona al menos un número'
                              : _seleccionados.length == 1
                                  ? 'Apartar número #${_seleccionados.first}'
                                  : 'Apartar ${_seleccionados.length} números',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.accent : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      key: const Key('banner_error_selector'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              context.read<UnirseTandaProvider>().clearErrors();
            },
            child: const Icon(Icons.close_rounded, color: AppColors.error, size: 18),
          ),
        ],
      ),
    );
  }
}
