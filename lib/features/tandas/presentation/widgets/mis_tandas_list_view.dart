import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';
import 'package:tandea/features/tandas/presentation/providers/tandas_provider.dart';
import 'package:tandea/features/tandas/presentation/widgets/tanda_card_item.dart';

/// Vista de lista reutilizable para "Mis Tandas" que implementa `ListView.builder`
/// con optimización de rendimiento mediante `Selector` por cada tarjeta.
class MisTandasListView extends StatefulWidget {
  final String rol; // 'participante' | 'organizador'

  const MisTandasListView({
    super.key,
    required this.rol,
  });

  @override
  State<MisTandasListView> createState() => _MisTandasListViewState();
}

class _MisTandasListViewState extends State<MisTandasListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.read<TandasProvider>().fetchMisTandas(rol: widget.rol);
      } catch (_) {
        // En entornos aislados donde no se inyectó el provider en el árbol
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    TandasProvider? provider;
    try {
      provider = context.watch<TandasProvider>();
    } catch (_) {
      // Fallback si el provider no está en el árbol de contexto
    }

    if (provider == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Mis tandas (${widget.rol})',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      );
    }

    final activeProvider = provider;
    final isOrganizador = widget.rol == 'organizador' || widget.rol == 'dueno';

    // 1. Estado de Carga
    if (activeProvider.isLoading && activeProvider.tandas.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    // 2. Estado de Error
    if (activeProvider.isError && activeProvider.tandas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'No se pudieron cargar tus tandas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                activeProvider.errorMessage ?? 'Ocurrió un error inesperado al conectar con el servidor.',
                style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                key: const Key('btn_reintentar_tandas'),
                onPressed: () {
                  activeProvider.fetchMisTandas(rol: widget.rol);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Estado Vacío (Sin tandas registradas para este rol)
    if (activeProvider.tandas.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => activeProvider.fetchMisTandas(rol: widget.rol),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOrganizador
                            ? Icons.assignment_ind_outlined
                            : Icons.savings_outlined,
                        size: 46,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isOrganizador
                          ? 'Aún no administras ninguna tanda'
                          : 'Aún no te has unido a ninguna tanda',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isOrganizador
                          ? 'Crea tu primer grupo de ahorro, define las reglas, los montos y comparte el código de invitación.'
                          : 'Pídele el código de 8 caracteres a tu organizador para unirte a un grupo y apartar tu turno.',
                      style: const TextStyle(
                        color: AppColors.textSecondaryLight,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      key: Key(isOrganizador ? 'btn_crear_tanda_empty' : 'btn_unirse_tanda_empty'),
                      onPressed: () {
                        if (isOrganizador) {
                          context.push(RouteNames.crearTanda);
                        } else {
                          context.push(RouteNames.unirseTanda);
                        }
                      },
                      icon: Icon(isOrganizador ? Icons.add_circle_outline_rounded : Icons.vpn_key_rounded),
                      label: Text(isOrganizador ? 'Crear nueva tanda' : 'Ingresar código de tanda'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 4. Lista con ListView.builder y Selector por cada tarjeta
    return RefreshIndicator(
      onRefresh: () => activeProvider.fetchMisTandas(rol: widget.rol),
      color: AppColors.primary,
      child: ListView.builder(
        key: const Key('list_mis_tandas'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8.0, bottom: 88.0),
        itemCount: activeProvider.cantidadTandas,
        itemBuilder: (context, index) {
          // Optimización solicitada: Selector individual por tarjeta
          return Selector<TandasProvider, TandaEntity>(
            key: ValueKey('selector_tanda_${activeProvider.tandas[index].id}'),
            selector: (_, p) => p.obtenerTandaEn(index),
            builder: (context, tanda, _) {
              return TandaCardItem(
                tanda: tanda,
                rol: widget.rol,
              );
            },
          );
        },
      ),
    );
  }
}
