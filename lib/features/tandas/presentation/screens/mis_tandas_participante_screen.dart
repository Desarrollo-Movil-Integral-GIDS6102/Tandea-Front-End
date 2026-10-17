import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tandea/core/constants/app_colors.dart';
import 'package:tandea/core/routes/route_names.dart';
import 'package:tandea/features/tandas/presentation/widgets/mis_tandas_list_view.dart';

/// Pantalla principal de Mis Tandas para el rol de Participante (ahorrador).
class MisTandasParticipanteScreen extends StatelessWidget {
  const MisTandasParticipanteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Mis tandas (participante)'),
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab_unirse_tanda'),
        onPressed: () {
          context.push(RouteNames.unirseTanda);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('Unirse a Tanda'),
      ),
      body: const MisTandasListView(
        rol: 'participante',
      ),
    );
  }
}
