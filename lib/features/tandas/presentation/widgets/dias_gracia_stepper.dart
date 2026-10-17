import 'package:flutter/material.dart';
import 'package:tandea/core/constants/app_colors.dart';

/// Stepper interactivo para ajustar los días de gracia permitidos en la tanda.
class DiasGraciaStepper extends StatelessWidget {
  final int valor;
  final VoidCallback onIncrementar;
  final VoidCallback onDecrementar;
  final ValueChanged<int>? onChanged;

  const DiasGraciaStepper({
    super.key,
    required this.valor,
    required this.onIncrementar,
    required this.onDecrementar,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.timelapse_rounded,
                  size: 20,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Días de gracia para pago',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Margen de tolerancia sin penalización',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Control del stepper
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      color: valor > 0 ? AppColors.primaryDark : AppColors.textDisabled,
                      splashRadius: 20,
                      onPressed: valor > 0 ? onDecrementar : null,
                      tooltip: 'Reducir días',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '$valor',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      color: AppColors.primaryDark,
                      splashRadius: 20,
                      onPressed: onIncrementar,
                      tooltip: 'Aumentar días',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Chips de selección rápida
          Wrap(
            spacing: 8,
            children: [0, 1, 2, 3, 5].map((dias) {
              final isSelected = valor == dias;
              return ChoiceChip(
                label: Text(dias == 0 ? 'Sin gracia' : '$dias d'),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (_) {
                  onChanged?.call(dias);
                },
                selectedColor: AppColors.primaryLight,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                backgroundColor: AppColors.background,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
