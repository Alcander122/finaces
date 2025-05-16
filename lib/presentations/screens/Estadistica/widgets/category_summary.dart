// category_summary.dart

import 'package:finances/core/data/providers/category_summary_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Para formato de moneda


final selectedTabProvider = StateProvider<bool>((ref) => false);

class CategorySummary extends ConsumerWidget {
  final void Function(String category, bool isExpense)? onCategoryTap;

  const CategorySummary({
    super.key,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);

    final AsyncValue<Map<String, Map<String, double>>> data =
        ref.watch(ingresosEgresosCategoryStreamProvider);

    return SizedBox(
      height: 500,
      child: Column(
        children: [
          // Pestañas INGRESO/EGRESO
          Row(
            children: [
              _buildCategoryTab(
                context: context,
                title: 'INGRESO',
                isSelected: !selectedTab,
                color: Colors.green,
                onTap: () => ref.read(selectedTabProvider.notifier).state = false,
              ),
              _buildCategoryTab(
                context: context,
                title: 'EGRESO',
                isSelected: selectedTab,
                color: Colors.red,
                onTap: () => ref.read(selectedTabProvider.notifier).state = true,
              ),
            ],
          ),

          // Lista de categorías con totales
          Expanded(
            child: data.when(
              data: (snapshotData) {
                final ingresosData = snapshotData['ingresos'] ?? {};
                final egresosData = snapshotData['egresos'] ?? {};

                final bool hasData = selectedTab
                    ? egresosData.isNotEmpty
                    : ingresosData.isNotEmpty;

                if (!hasData) {
                  return const Center(child: Text('No hay datos'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: selectedTab ? egresosData.length : ingresosData.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final category = selectedTab
                        ? egresosData.keys.elementAt(index)
                        : ingresosData.keys.elementAt(index);

                    final amount = selectedTab
                        ? egresosData.values.elementAt(index)
                        : ingresosData.values.elementAt(index);

                    return ListTile(
                      title: Text(category),
                      trailing: Text(
                        formatCurrency(amount),
                        style: TextStyle(
                          color: selectedTab ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => onCategoryTap?.call(category, selectedTab),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  // Componente reutilizable para pestañas
  Widget _buildCategoryTab({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.grey[200],
            border: Border(
              bottom: BorderSide(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey?[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Formateador de moneda
  String formatCurrency(double value) {
    final formatter = NumberFormat.decimalPattern('es_CO');
    return '\$${formatter.format(value)}';
  }
}