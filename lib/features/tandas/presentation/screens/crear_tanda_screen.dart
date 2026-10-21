import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/core/widgets/primary_button.dart';
import 'package:tandea/features/tandas/domain/services/calcular_plan.dart';
import 'package:tandea/features/tandas/presentation/providers/crear_tanda_provider.dart';
import 'package:tandea/features/tandas/presentation/widgets/dias_gracia_stepper.dart';
import 'package:tandea/features/tandas/presentation/widgets/resumen_estimado_card.dart';
import 'package:tandea/injection/injection.dart';

/// Pantalla para la creación de una nueva tanda con resumen estimado en tiempo real.
class CrearTandaScreen extends StatelessWidget {
  const CrearTandaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<CrearTandaProvider>(),
      child: const _CrearTandaView(),
    );
  }
}

class _CrearTandaView extends StatefulWidget {
  const _CrearTandaView();

  @override
  State<_CrearTandaView> createState() => _CrearTandaViewState();
}

class _CrearTandaViewState extends State<_CrearTandaView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _cuotaController;
  late final TextEditingController _participantesController;
  late final TextEditingController _vueltasController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<CrearTandaProvider>();
    _nameController = TextEditingController(text: provider.name);
    _descriptionController = TextEditingController(text: provider.description);
    _cuotaController = TextEditingController(
      text: provider.montoCuota > 0 ? provider.montoCuota.toStringAsFixed(0) : '',
    );
    _participantesController = TextEditingController(
      text: provider.numParticipantes.toString(),
    );
    _vueltasController = TextEditingController(
      text: provider.numRounds.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cuotaController.dispose();
    _participantesController.dispose();
    _vueltasController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaInicio(BuildContext context) async {
    final provider = context.read<CrearTandaProvider>();
    final hoy = DateTime.now();
    final primerFecha = hoy;
    final ultimaFecha = hoy.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: provider.startDate.isBefore(primerFecha) ? primerFecha : provider.startDate,
      firstDate: primerFecha,
      lastDate: ultimaFecha,
      helpText: 'Selecciona la fecha del primer turno',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (picked != null) {
      provider.setFechaInicio(picked);
    }
  }

  String _formatFechaVisual(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _onSubmit(BuildContext context) async {
    final provider = context.read<CrearTandaProvider>();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await provider.crearTanda();
    if (!context.mounted) return;

    if (success && provider.createdTanda != null) {
      final tanda = provider.createdTanda!;
      final inviteCode = tanda.inviteCode ?? 'TND-OK';

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¡Tanda creada exitosamente!',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Comparte este código de invitación con los participantes para que se unan a la tanda:',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SelectableText(
                      inviteCode,
                      style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: AppColors.primaryDark,
                          ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                      tooltip: 'Copiar código',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Código copiado al portapapeles'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Compartir código',
                icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push(RouteNames.compartirCodigo, extra: tanda);
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.pop();
                  },
                  child: const Text('Ir a mis tandas'),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CrearTandaProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Crear nueva tanda'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner de error si ocurre alguno
                if (provider.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            provider.errorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                          onPressed: provider.clearError,
                        ),
                      ],
                    ),
                  ),
                ],

                // 1. Resumen Estimado en Tiempo Real (Espejo de calcularPlan)
                ResumenEstimadoCard(
                  plan: provider.planEstimado,
                  periodicidad: provider.periodicidad,
                  montoCuota: provider.montoCuota,
                  tieneNumeroMuerto: provider.hasDeadNumber,
                ),
                const SizedBox(height: 24),

                // 2. Información General
                _buildSectionTitle(theme, 'Información general', Icons.badge_outlined),
                const SizedBox(height: 12),

                // Nombre de la tanda
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la tanda *',
                    hintText: 'Ej. Tanda Navideña 2026',
                    prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
                  ),
                  maxLength: 150,
                  onChanged: provider.setNombre,
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Descripción opcional
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    hintText: 'Ej. Ahorro para compras de fin de año',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 2,
                  maxLength: 500,
                  onChanged: provider.setDescripcion,
                ),
                const SizedBox(height: 8),

                // Selector de Fecha de Inicio
                InkWell(
                  onTap: () => _seleccionarFechaInicio(context),
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de inicio del primer turno *',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      _formatFechaVisual(provider.startDate),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Frecuencia y Aportaciones
                _buildSectionTitle(theme, 'Aportaciones y Periodicidad', Icons.payments_outlined),
                const SizedBox(height: 12),

                // Monto de la cuota
                TextFormField(
                  controller: _cuotaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Monto de cuota por participante *',
                    hintText: '1000.00',
                    prefixText: '\$ ',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                    suffixText: 'MXN',
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val);
                    provider.setMontoCuota(d ?? 0.0);
                  },
                  validator: (val) {
                    final d = double.tryParse(val ?? '');
                    if (d == null || d <= 0) {
                      return 'Ingresa un monto válido mayor a 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // SegmentedButton para Periodicidad
                Text(
                  'Periodicidad de los turnos *',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<PeriodicidadTanda>(
                  segments: const [
                    ButtonSegment(
                      value: PeriodicidadTanda.diaria,
                      label: Text('Diaria'),
                    ),
                    ButtonSegment(
                      value: PeriodicidadTanda.semanal,
                      label: Text('Semanal'),
                    ),
                    ButtonSegment(
                      value: PeriodicidadTanda.quincenal,
                      label: Text('Quincenal'),
                    ),
                    ButtonSegment(
                      value: PeriodicidadTanda.mensual,
                      label: Text('Mensual'),
                    ),
                  ],
                  selected: {provider.periodicidad},
                  onSelectionChanged: (Set<PeriodicidadTanda> newSelection) {
                    provider.setPeriodicidad(newSelection.first);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary;
                      }
                      return Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return AppColors.textPrimary;
                    }),
                    textStyle: WidgetStateProperty.all(
                      const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    side: WidgetStateProperty.all(
                      const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Participantes y Vueltas
                _buildSectionTitle(theme, 'Participantes y Rondas', Icons.group_outlined),
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Número de participantes
                    Expanded(
                      child: TextFormField(
                        controller: _participantesController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Participantes *',
                          hintText: '5',
                          prefixIcon: Icon(Icons.people_alt_outlined),
                        ),
                        onChanged: (val) {
                          final n = int.tryParse(val);
                          provider.setNumParticipantes(n ?? 0);
                        },
                        validator: (val) {
                          final n = int.tryParse(val ?? '');
                          if (n == null || n < 2) {
                            return 'Mínimo 2';
                          }
                          if (n > 50) {
                            return 'Máx. 50';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Número de vueltas (rondas)
                    Expanded(
                      child: TextFormField(
                        controller: _vueltasController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Rondas/Vueltas *',
                          hintText: '1',
                          prefixIcon: Icon(Icons.replay_rounded),
                        ),
                        onChanged: (val) {
                          final n = int.tryParse(val);
                          provider.setNumRounds(n ?? 1);
                        },
                        validator: (val) {
                          final n = int.tryParse(val ?? '');
                          if (n == null || n < 1) {
                            return 'Mínimo 1';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Reglas, Tolerancia y Configuración Avanzada
                _buildSectionTitle(theme, 'Reglas de operación', Icons.tune_rounded),
                const SizedBox(height: 12),

                // Stepper para días de gracia
                DiasGraciaStepper(
                  valor: provider.graceDays,
                  onIncrementar: provider.incrementarDiasGracia,
                  onDecrementar: provider.decrementarDiasGracia,
                  onChanged: provider.setDiasGracia,
                ),
                const SizedBox(height: 14),

                // Switch para Asignación (Aleatoria / Sorteo vs Manual / Tradicional)
                Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile.adaptive(
                    value: provider.isRandomAssignment,
                    onChanged: provider.setAsignacionAleatoria,
                    activeTrackColor: AppColors.primary,
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shuffle_rounded,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Asignación por sorteo',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      provider.isRandomAssignment
                          ? 'Los turnos se rifan aleatoriamente entre los miembros.'
                          : 'Asignación manual: cada participante elige su número (Tradicional).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Switch para Número Muerto
                Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile.adaptive(
                    value: provider.hasDeadNumber,
                    onChanged: provider.setTieneNumeroMuerto,
                    activeTrackColor: AppColors.primary,
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Número muerto de respaldo',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      provider.hasDeadNumber
                          ? 'Reserva un turno adicional como fondo de protección contra impagos.'
                          : 'Sin turno muerto: se reparten únicamente los números de los participantes.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Botón Enviar a POST /tandas
                PrimaryButton(
                  text: 'Crear tanda',
                  icon: const Icon(Icons.add_task_rounded, color: Colors.white, size: 20),
                  isLoading: provider.isLoading,
                  onPressed: () => _onSubmit(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
