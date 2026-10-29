import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/widgets/primary_button.dart';
import 'package:tandea/features/auth/presentation/providers/perfil_provider.dart';

/// Cambio de contraseña en dos pasos: enviar código de 6 dígitos al correo y
/// capturarlo junto con la nueva contraseña.
class CambiarPasswordScreen extends StatefulWidget {
  /// Correo al que llegará el código (solo para mostrarlo).
  final String? correo;

  const CambiarPasswordScreen({super.key, this.correo});

  @override
  State<CambiarPasswordScreen> createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  final _password = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _ocultar = true;

  @override
  void dispose() {
    _codigo.dispose();
    _password.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _cambiar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final ok = await context.read<PerfilProvider>().cambiarPassword(
          codigo: _codigo.text,
          nuevaPassword: _password.text,
        );
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Contraseña actualizada'),
      backgroundColor: AppColors.success,
    ));
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerfilProvider>();
    final correo = widget.correo;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              correo != null
                  ? 'Te enviaremos un código de 6 dígitos a $correo. Vence en 10 minutos.'
                  : 'Te enviaremos un código de 6 dígitos a tu correo. Vence en 10 minutos.',
              style: const TextStyle(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 16),
            if (provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  provider.errorMessage!,
                  key: const Key('password_error'),
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                ),
              ),
            if (provider.mensaje != null && provider.codigoEnviado)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(provider.mensaje!, style: const TextStyle(color: AppColors.success)),
              ),
            if (!provider.codigoEnviado)
              PrimaryButton(
                key: const Key('btn_enviar_codigo'),
                text: 'Enviar código',
                isLoading: provider.enviandoCodigo,
                onPressed: provider.enviandoCodigo ? null : provider.enviarCodigo,
              )
            else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('campo_codigo'),
                      controller: _codigo,
                      decoration: const InputDecoration(
                        labelText: 'Código de 6 dígitos',
                        counterText: '',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                          RegExp(r'^\d{6}$').hasMatch(v ?? '') ? null : 'Escribe los 6 dígitos',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('campo_nueva_password'),
                      controller: _password,
                      obscureText: _ocultar,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(_ocultar ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _ocultar = !_ocultar),
                        ),
                      ),
                      validator: (v) => (v ?? '').length < 8 ? 'Mínimo 8 caracteres' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('campo_confirmar_password'),
                      controller: _confirmacion,
                      obscureText: _ocultar,
                      decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
                      validator: (v) =>
                          v == _password.text ? null : 'Las contraseñas no coinciden',
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      key: const Key('btn_cambiar_password'),
                      text: 'Cambiar contraseña',
                      isLoading: provider.cambiandoPassword,
                      onPressed: provider.cambiandoPassword ? null : _cambiar,
                    ),
                    TextButton(
                      key: const Key('btn_reenviar_codigo'),
                      onPressed: provider.enviandoCodigo ? null : provider.enviarCodigo,
                      child: const Text('Reenviar código'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
