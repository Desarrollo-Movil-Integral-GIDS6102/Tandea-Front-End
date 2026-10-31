import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/utils/formato_moneda.dart';
import 'package:tandea/core/widgets/primary_button.dart';
import 'package:tandea/features/entregas/presentation/providers/entrega_provider.dart';

/// Quien cobra ve la evidencia y confirma que recibió el dinero, o reporta un problema.
class ConfirmarEntregaScreen extends StatelessWidget {
  final int idPayout;

  const ConfirmarEntregaScreen({super.key, required this.idPayout});

  Future<void> _confirmar(BuildContext context) async {
    final ok = await context.read<EntregaProvider>().confirmar(idPayout);
    if (ok && context.mounted) context.pop();
  }

  Future<void> _reportar(BuildContext context) async {
    var texto = '';
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reportar problema'),
        content: TextField(
          key: const Key('campo_motivo_problema'),
          onChanged: (valor) => texto = valor,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(labelText: '¿Qué ocurrió?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            key: const Key('btn_enviar_problema'),
            onPressed: () => Navigator.pop(ctx, texto.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (motivo == null || motivo.isEmpty || !context.mounted) return;

    final ok = await context.read<EntregaProvider>().reportarProblema(idPayout, motivo);
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Reportamos el problema. El turno sigue abierto.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EntregaProvider>();
    final entrega = provider.entrega;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar recepción')),
      body: SafeArea(
        child: entrega == null
            ? Center(
                child: provider.cargando
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : Text(provider.errorMessage ?? 'No se pudo cargar la entrega.'),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${entrega.nombreTanda} · Turno #${entrega.numero}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Total: ${formatearMonedaMxn(entrega.total)}', key: const Key('entrega_total')),
                  Text('Transferencia: ${formatearMonedaMxn(entrega.transferencia)}'),
                  Text('Efectivo: ${formatearMonedaMxn(entrega.efectivo)}'),
                  const SizedBox(height: 16),
                  if (entrega.evidenciaUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        entrega.evidenciaUrl!,
                        key: const Key('entrega_evidencia'),
                        errorBuilder: (_, _, _) => const Text('No se pudo mostrar la evidencia.'),
                      ),
                    ),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (entrega.confirmada)
                    const Text(
                      'Ya confirmaste esta entrega.',
                      key: Key('entrega_confirmada'),
                      textAlign: TextAlign.center,
                    )
                  else ...[
                    PrimaryButton(
                      key: const Key('btn_si_la_recibi'),
                      text: 'Sí, la recibí',
                      isLoading: provider.enviando,
                      onPressed: () => _confirmar(context),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const Key('btn_reportar_problema'),
                      onPressed: provider.enviando ? null : () => _reportar(context),
                      child: const Text('Reportar problema'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
