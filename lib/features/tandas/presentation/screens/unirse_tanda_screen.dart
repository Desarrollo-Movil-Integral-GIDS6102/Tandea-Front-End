import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/core/utils/uppercase_text_formatter.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/domain/entities/unirse_tanda_result.dart';
import 'package:tandea/features/tandas/presentation/providers/unirse_tanda_provider.dart';

/// Pantalla para unirse a una tanda activa mediante código de invitación.
class UnirseTandaScreen extends StatefulWidget {
  final String? initialCode;

  const UnirseTandaScreen({
    super.key,
    this.initialCode,
  });

  @override
  State<UnirseTandaScreen> createState() => _UnirseTandaScreenState();
}

class _UnirseTandaScreenState extends State<UnirseTandaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<UnirseTandaProvider>();
      provider.clearErrors();
      if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
        provider.setInviteCode(widget.initialCode!);
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleBuscarTanda() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = context.read<UnirseTandaProvider>();
    provider.setInviteCode(_codeController.text.trim());
    final tanda = await provider.consultarTanda();

    if (!mounted || tanda == null) {
      return;
    }

    // Si es por elección, ir directamente a la pantalla de selección de número
    if (provider.isPorEleccion) {
      await context.push(RouteNames.seleccionarNumero, extra: tanda);
    } else {
      // Si es asignación por sorteo/automática, mostrar modal de confirmación antes de unirse
      _mostrarDialogoConfirmacionSorteo(tanda);
    }
  }

  void _mostrarDialogoConfirmacionSorteo(TandaEntity tanda) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        final provider = context.watch<UnirseTandaProvider>();
        final isLoading = provider.isLoading;

        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.casino_outlined, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tanda.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tanda con asignación por sorteo',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _buildDetalleFila(
                      'Monto por cuota:',
                      '\$${tanda.monto.toStringAsFixed(2)}',
                      isBold: true,
                    ),
                    const Divider(height: 16),
                    _buildDetalleFila('Participantes:', '${tanda.totalParticipantes} miembros'),
                    const Divider(height: 16),
                    _buildDetalleFila('Periodicidad:', tanda.periodo.toUpperCase()),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'El número de turno se te asignará de forma aleatoria o según el orden de llegada.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              if (provider.backendError != null) ...[
                _buildErrorBanner(provider.backendError!),
                const SizedBox(height: 14),
              ],
              ElevatedButton(
                key: const Key('btn_confirmar_sorteo'),
                onPressed: isLoading
                    ? null
                    : () async {
                        final resultado = await provider.unirse();
                        if (resultado != null && mounted) {
                          if (bottomSheetContext.mounted) {
                            Navigator.of(bottomSheetContext).pop();
                          }
                          _mostrarExitoDialog(resultado);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                    : const Text(
                        'Confirmar y Unirme',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarExitoDialog(UnirseTandaResult result) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 28),
            SizedBox(width: 10),
            Text('¡Te has unido!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Te registraste exitosamente en la tanda "${result.tanda.nombre}".',
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Tu Turno Asignado: ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  Text(
                    '#${result.numeroAsignado}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            key: const Key('btn_exito_ir_tandas'),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.go(RouteNames.tandasParticipante);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ir a Mis Tandas'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleFila(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: AppColors.textPrimaryLight,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<UnirseTandaProvider>();
    final isLoading = provider.isLoading;

    final errorMessage = provider.validationError ?? provider.backendError;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Unirse a una Tanda'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icono y Cabecera
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.group_add_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Ingresa el Código de Invitación',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escribe el código de invitación que te compartió el organizador para consultar la tanda.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Tarjeta del Formulario
                  Card(
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: 0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: AppColors.surfaceLight,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Banner de error (muestra validación local o error devuelto del backend)
                            if (errorMessage != null) ...[
                              _buildErrorBanner(errorMessage),
                              const SizedBox(height: 20),
                            ],

                            // Etiqueta del campo
                            const Text(
                              'Código de invitación',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // TextField con mayúsculas y formateador
                            TextFormField(
                              key: const Key('input_codigo_tanda'),
                              controller: _codeController,
                              enabled: !isLoading,
                              textCapitalization: TextCapitalization.characters,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4.0,
                                color: AppColors.primary,
                              ),
                              inputFormatters: [
                                UpperCaseTextFormatter(),
                                LengthLimitingTextInputFormatter(UnirseTandaProvider.codigoMaxLength),
                                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                              ],
                              decoration: InputDecoration(
                                hintText: 'TND-7K9A2B',
                                hintStyle: TextStyle(
                                  fontSize: 22,
                                  letterSpacing: 4.0,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppColors.primary),
                                suffixIcon: _codeController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 20),
                                        onPressed: () {
                                          _codeController.clear();
                                          provider.setInviteCode('');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: AppColors.backgroundLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                ),
                                counterText:
                                    '${_codeController.text.length}/${UnirseTandaProvider.codigoMaxLength}',
                              ),
                              onChanged: (value) {
                                final upper = value.toUpperCase();
                                if (value != upper) {
                                  _codeController.value = _codeController.value.copyWith(
                                    text: upper,
                                    selection: TextSelection.collapsed(offset: upper.length),
                                  );
                                }
                                provider.setInviteCode(upper);
                                setState(() {});
                              },
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) {
                                  return 'Ingresa el código de la tanda';
                                }
                                if (text.length < UnirseTandaProvider.codigoMinLength ||
                                    text.length > UnirseTandaProvider.codigoMaxLength ||
                                    !UnirseTandaProvider.regexCodigo.hasMatch(text)) {
                                  return 'El código debe tener entre ${UnirseTandaProvider.codigoMinLength} y ${UnirseTandaProvider.codigoMaxLength} caracteres';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _handleBuscarTanda(),
                            ),
                            const SizedBox(height: 24),

                            // Botón de Enviar
                            ElevatedButton(
                              key: const Key('btn_buscar_tanda'),
                              onPressed: isLoading ? null : _handleBuscarTanda,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
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
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Continuar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, size: 20),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nota informativa
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Si la tanda es tradicional (por elección), podrás seleccionar tu número favorito en el siguiente paso. Si es por sorteo, tu número se asignará automáticamente.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimaryLight,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      key: const Key('banner_error_tanda'),
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
