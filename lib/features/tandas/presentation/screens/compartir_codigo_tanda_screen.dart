import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/services/share_service.dart';
import 'package:tandea/core/widgets/primary_button.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/injection/injection.dart';

/// Pantalla dedicada a visualizar y compartir el código de invitación de una tanda.
///
/// Ofrece:
/// - Código grande con botón de copia rápida al portapapeles (Clipboard).
/// - Mensaje prellenado y formateado con sintaxis de negritas y emojis para WhatsApp.
/// - Botón principal de compartir nativo mediante `share_plus`.
class CompartirCodigoTandaScreen extends StatefulWidget {
  final String inviteCode;
  final String? nombreTanda;
  final double? monto;
  final String? periodo;
  final int? totalParticipantes;
  final TandaEntity? tanda;
  final ShareService? shareService;

  const CompartirCodigoTandaScreen({
    super.key,
    required this.inviteCode,
    this.nombreTanda,
    this.monto,
    this.periodo,
    this.totalParticipantes,
    this.tanda,
    this.shareService,
  });

  @override
  State<CompartirCodigoTandaScreen> createState() => _CompartirCodigoTandaScreenState();
}

class _CompartirCodigoTandaScreenState extends State<CompartirCodigoTandaScreen> {
  late final ShareService _shareService;
  bool _codigoCopiado = false;
  bool _mensajeCopiado = false;
  Timer? _codigoResetTimer;
  Timer? _mensajeResetTimer;

  @override
  void initState() {
    super.initState();
    _shareService = widget.shareService ?? (sl.isRegistered<ShareService>() ? sl<ShareService>() : ShareServiceImpl());
  }

  @override
  void dispose() {
    _codigoResetTimer?.cancel();
    _mensajeResetTimer?.cancel();
    super.dispose();
  }

  String get _nombre {
    return widget.nombreTanda ?? widget.tanda?.nombre ?? 'Tanda Comunitaria';
  }

  double? get _monto {
    return widget.monto ?? widget.tanda?.monto;
  }

  String? get _periodo {
    return widget.periodo ?? widget.tanda?.periodo;
  }

  int? get _participantes {
    return widget.totalParticipantes ?? widget.tanda?.totalParticipantes;
  }

  String _generarTextoWhatsApp() {
    final buffer = StringBuffer();
    buffer.writeln('🌟 *¡Hola! Te invito a unirte a mi tanda en Tandea:*');
    buffer.writeln();
    buffer.writeln('📌 *Tanda:* $_nombre');
    if (_monto != null && _monto! > 0) {
      final partes = _monto!.toStringAsFixed(2).split('.');
      final entero = partes[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      buffer.writeln('💰 *Aportación:* \$$entero.${partes[1]} MXN');
    }
    if (_periodo != null && _periodo!.isNotEmpty) {
      final p = _periodo!;
      final cap = '${p[0].toUpperCase()}${p.substring(1)}';
      buffer.writeln('🗓️ *Periodicidad:* $cap');
    }
    if (_participantes != null && _participantes! > 0) {
      buffer.writeln('👥 *Participantes:* $_participantes');
    }
    buffer.writeln();
    buffer.writeln('🔑 *Código de invitación:*');
    buffer.writeln('👉 *${widget.inviteCode}* 👈');
    buffer.writeln();
    buffer.writeln('📲 *¿Cómo unirte?*');
    buffer.writeln('1. Abre la app *Tandea*.');
    buffer.writeln('2. Ve a la sección *"Unirse a una tanda"*.');
    buffer.writeln('3. Ingresa el código *${widget.inviteCode}*.');
    buffer.writeln();
    buffer.writeln('¡Ahorremos juntos y alcancemos nuestras metas! 🚀');

    return buffer.toString();
  }

  Future<void> _copiarCodigo() async {
    await Clipboard.setData(ClipboardData(text: widget.inviteCode));
    if (!mounted) return;

    setState(() {
      _codigoCopiado = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Código "${widget.inviteCode}" copiado al portapapeles.'),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    _codigoResetTimer?.cancel();
    _codigoResetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _codigoCopiado = false;
        });
      }
    });
  }

  Future<void> _copiarMensajeCompleto() async {
    final mensaje = _generarTextoWhatsApp();
    await Clipboard.setData(ClipboardData(text: mensaje));
    if (!mounted) return;

    setState(() {
      _mensajeCopiado = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mensaje completo para WhatsApp copiado al portapapeles.'),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    _mensajeResetTimer?.cancel();
    _mensajeResetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _mensajeCopiado = false;
        });
      }
    });
  }

  Future<void> _compartirConSharePlus() async {
    final mensaje = _generarTextoWhatsApp();
    await _shareService.shareText(
      mensaje,
      subject: 'Invitación a unirse a la tanda "$_nombre"',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mensajeWhatsApp = _generarTextoWhatsApp();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Compartir tanda'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado decorativo
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.share_rounded,
                    size: 32,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Invita a tus participantes',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Comparte el código único con tus conocidos para que puedan ingresar y elegir su turno.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ── 1. Tarjeta con el CÓDIGO GRANDE ─────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'CÓDIGO DE INVITACIÓN',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // CÓDIGO GRANDE
                    SelectableText(
                      widget.inviteCode,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                        color: AppColors.primaryDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),

                    // Botón de Copiar Código (Clipboard)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _copiarCodigo,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: _codigoCopiado ? AppColors.success : AppColors.primary,
                            width: 1.5,
                          ),
                          backgroundColor: _codigoCopiado
                              ? AppColors.success.withValues(alpha: 0.1)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(
                          _codigoCopiado ? Icons.check_circle_rounded : Icons.copy_rounded,
                          color: _codigoCopiado ? AppColors.success : AppColors.primaryDark,
                          size: 20,
                        ),
                        label: Text(
                          _codigoCopiado ? '¡Código copiado!' : 'Copiar código',
                          style: TextStyle(
                            color: _codigoCopiado ? AppColors.success : AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 2. Vista Previa del Mensaje para WhatsApp ────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabecera estilo WhatsApp
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Color(0xFF2E7D32),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Texto prellenado para WhatsApp',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _copiarMensajeCompleto,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _mensajeCopiado ? Icons.check : Icons.copy,
                                    size: 16,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _mensajeCopiado ? 'Copiado' : 'Copiar',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: const Color(0xFF2E7D32),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Cuerpo del mensaje prellenado
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                        ),
                        child: SelectableText(
                          mensajeWhatsApp,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF14532D),
                            height: 1.45,
                            fontFamily: 'monospace',
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── 3. Botones de Compartir (share_plus) ─────────────────────
              PrimaryButton(
                text: 'Compartir invitación',
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _compartirConSharePlus,
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _copiarMensajeCompleto,
                icon: const Icon(Icons.content_copy_rounded, size: 18),
                label: const Text('Copiar texto de invitación'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
