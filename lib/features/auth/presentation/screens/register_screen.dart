import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/constants/app_constants.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/features/auth/domain/entities/user_role.dart';
import 'package:tandea/features/auth/presentation/providers/auth_provider.dart';
import 'package:tandea/features/auth/presentation/utils/register_validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _emailController;
  late final TextEditingController _edadController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _apellidoController = TextEditingController();
    _emailController = TextEditingController();
    _edadController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Limpiar errores previos al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthProvider>().clearError();
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _edadController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Cerrar teclado
    FocusScope.of(context).unfocus();

    // Evitar solicitudes duplicadas mientras hay un registro en curso
    if (context.read<AuthProvider>().isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      // Tras el primer intento, revalidar mientras el usuario corrige
      if (_autovalidateMode != AutovalidateMode.onUserInteraction) {
        setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      }
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final int? edad = _edadController.text.trim().isNotEmpty
        ? int.tryParse(_edadController.text.trim())
        : null;

    final success = await authProvider.register(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      edad: edad,
    );

    if (!mounted) return;

    if (success) {
      final user = authProvider.currentUser;
      final role = user != null ? UserRole.fromString(user.rol) : UserRole.usuario;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Registro exitoso! Bienvenido a ${AppConstants.appName}',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );


      final destination = role.isAdminGlobal ? RouteNames.admin : RouteNames.tandasParticipante;
      context.go(destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.login);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado
                  Text(
                    'Únete a Tandea',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Organiza y participa en tandas de manera transparente y segura',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Tarjeta del Formulario
                  Card(
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: AppColors.surfaceLight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _autovalidateMode,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Mensaje de Error si el estado es error
                            if (authProvider.isError && authProvider.errorMessage != null) ...[
                              _buildErrorBanner(context, authProvider.errorMessage!),
                              const SizedBox(height: 20),
                            ],

                            // Nombre
                            TextFormField(
                              controller: _nombreController,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              enabled: !isLoading,
                              decoration: const InputDecoration(
                                labelText: 'Nombre *',
                                hintText: 'Ej. Juan',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              forceErrorText: authProvider.fieldErrors['name'],
                              onChanged: (_) => authProvider.limpiarErrorCampo('name'),
                              validator: RegisterValidators.nombre,
                            ),
                            const SizedBox(height: 16),

                            // Apellido
                            TextFormField(
                              controller: _apellidoController,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              enabled: !isLoading,
                              decoration: const InputDecoration(
                                labelText: 'Apellido *',
                                hintText: 'Ej. Pérez',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              forceErrorText: authProvider.fieldErrors['lastName'],
                              onChanged: (_) => authProvider.limpiarErrorCampo('lastName'),
                              validator: RegisterValidators.apellido,
                            ),
                            const SizedBox(height: 16),

                            // Correo Electrónico
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico *',
                                hintText: 'ejemplo@tandea.app',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              forceErrorText: authProvider.fieldErrors['email'],
                              onChanged: (_) => authProvider.limpiarErrorCampo('email'),
                              validator: RegisterValidators.email,
                            ),
                            const SizedBox(height: 16),

                            // Edad (Opcional, pero >= 18 por regla de negocio)
                            TextFormField(
                              controller: _edadController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              enabled: !isLoading,
                              decoration: const InputDecoration(
                                labelText: 'Edad (opcional)',
                                hintText: 'Mayor de 18 años',
                                prefixIcon: Icon(Icons.cake_outlined),
                              ),
                              forceErrorText: authProvider.fieldErrors['age'],
                              onChanged: (_) => authProvider.limpiarErrorCampo('age'),
                              validator: RegisterValidators.edad,
                            ),
                            const SizedBox(height: 16),

                            // Contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: 'Contraseña *',
                                hintText: 'Mínimo ${RegisterValidators.minPasswordLength} caracteres',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  tooltip: _obscurePassword
                                      ? 'Mostrar contraseña'
                                      : 'Ocultar contraseña',
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              forceErrorText: authProvider.fieldErrors['password'],
                              onChanged: (_) => authProvider.limpiarErrorCampo('password'),
                              validator: RegisterValidators.password,
                            ),
                            const SizedBox(height: 16),

                            // Confirmar Contraseña
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              enabled: !isLoading,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              onFieldSubmitted: (_) => _handleRegister(),
                              decoration: InputDecoration(
                                labelText: 'Confirmar contraseña *',
                                hintText: 'Repite tu contraseña',
                                prefixIcon: const Icon(Icons.lock_reset_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  tooltip: _obscureConfirmPassword
                                      ? 'Mostrar contraseña'
                                      : 'Ocultar contraseña',
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) => RegisterValidators.confirmPassword(value, _passwordController.text),
                            ),
                            const SizedBox(height: 28),

                            // Botón Registrarse
                            ElevatedButton(
                              onPressed: isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                      'Registrarse',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Enlace a Iniciar Sesión
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes una cuenta? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(RouteNames.login);
                                }
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: const Text(
                          'Inicia sesión aquí',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              context.read<AuthProvider>().clearError();
            },
            child: const Icon(
              Icons.close,
              color: AppColors.error,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
