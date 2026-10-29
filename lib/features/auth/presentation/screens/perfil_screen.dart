import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/core/widgets/primary_button.dart';
import 'package:tandea/features/auth/domain/entities/user_entity.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/auth/presentation/providers/perfil_provider.dart';

/// Gestión del perfil: editar datos personales, cambiar contraseña y cerrar sesión.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Tendrás que volver a iniciar sesión para usar Tandea.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            key: const Key('btn_confirmar_cerrar_sesion'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (context.mounted) context.go(RouteNames.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerfilProvider>();
    final perfil = provider.perfil;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Mi perfil')),
      body: SafeArea(
        child: perfil == null
            ? Center(
                child: provider.cargando
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(provider.errorMessage ?? 'No se pudo cargar tu perfil.'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: provider.cargar,
                            child: const Text('Reintentar'),
                          ),
                          TextButton(
                            onPressed: () => _cerrarSesion(context),
                            child: const Text('Cerrar sesión'),
                          ),
                        ],
                      ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _Encabezado(perfil: perfil),
                  const SizedBox(height: 24),
                  // La key reinicia el formulario cuando cambian los datos guardados
                  _FormularioPerfil(key: ValueKey(perfil), perfil: perfil),
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      key: const Key('btn_ir_cambiar_password'),
                      leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                      title: const Text('Cambiar contraseña'),
                      subtitle: const Text('Te enviaremos un código de 6 dígitos a tu correo'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(RouteNames.cambiarPassword, extra: perfil.email),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    key: const Key('btn_cerrar_sesion'),
                    onPressed: () => _cerrarSesion(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Cerrar sesión'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final UserEntity perfil;

  const _Encabezado({required this.perfil});

  @override
  Widget build(BuildContext context) {
    final inicial = perfil.nombre.isNotEmpty ? perfil.nombre[0].toUpperCase() : '?';
    return Column(
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: AppColors.primary,
          child: Text(
            inicial,
            style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          perfil.nombreCompleto,
          key: const Key('perfil_nombre_completo'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(perfil.email, style: const TextStyle(color: AppColors.textSecondaryLight)),
      ],
    );
  }
}

class _FormularioPerfil extends StatefulWidget {
  final UserEntity perfil;

  const _FormularioPerfil({super.key, required this.perfil});

  @override
  State<_FormularioPerfil> createState() => _FormularioPerfilState();
}

class _FormularioPerfilState extends State<_FormularioPerfil> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.perfil.nombre);
  late final _apellido = TextEditingController(text: widget.perfil.apellido ?? '');
  late final _edad = TextEditingController(text: widget.perfil.edad?.toString() ?? '');
  late final _genero = TextEditingController(text: widget.perfil.genero ?? '');

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _edad.dispose();
    _genero.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final provider = context.read<PerfilProvider>();
    final ok = await provider.guardar(
      nombre: _nombre.text,
      apellido: _apellido.text,
      edad: int.tryParse(_edad.text.trim()),
      genero: _genero.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Perfil actualizado' : provider.errorMessage ?? 'No se pudo guardar'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  static String? _requerido(String? v, String campo) =>
      (v == null || v.trim().isEmpty) ? '$campo es requerido' : null;

  @override
  Widget build(BuildContext context) {
    final guardando = context.select<PerfilProvider, bool>((p) => p.guardando);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('campo_perfil_nombre'),
            controller: _nombre,
            decoration: const InputDecoration(labelText: 'Nombre'),
            textCapitalization: TextCapitalization.words,
            validator: (v) => _requerido(v, 'El nombre'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('campo_perfil_apellido'),
            controller: _apellido,
            decoration: const InputDecoration(labelText: 'Apellido'),
            textCapitalization: TextCapitalization.words,
            validator: (v) => _requerido(v, 'El apellido'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('campo_perfil_edad'),
            controller: _edad,
            decoration: const InputDecoration(labelText: 'Edad (opcional)'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              final edad = int.tryParse(v?.trim() ?? '');
              if (v != null && v.trim().isNotEmpty && (edad == null || edad < 18)) {
                return 'Debes ser mayor de edad';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('campo_perfil_genero'),
            controller: _genero,
            decoration: const InputDecoration(labelText: 'Género (opcional)'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: widget.perfil.email,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Correo',
              helperText: 'El correo no se puede cambiar',
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            key: const Key('btn_guardar_perfil'),
            text: 'Guardar cambios',
            isLoading: guardando,
            onPressed: guardando ? null : _guardar,
          ),
        ],
      ),
    );
  }
}
