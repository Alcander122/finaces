// category_summary.dart
import 'package:finances/core/data/providers/category_summary_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final selectedTabProvider = StateProvider<bool>((ref) => false);

class CategorySummary extends ConsumerWidget {
  final void Function(String category, bool isExpense)? onCategoryTap;

  const CategorySummary({super.key, this.onCategoryTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);
    final summaryAsync = ref.watch(ingresosEgresosCategoryStreamProvider);

    return SizedBox(
      height: 500,
      child: Column(
        children: [
          _buildTabSelector(ref, selectedTab),
          Expanded(
            child: summaryAsync.when(
              data: (summaryData) => _buildCategoryList(
                selectedTab,
                summaryData['ingresos'] ?? {},
                summaryData['egresos'] ?? {},
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Error: ${error.toString()}',
                    style: TextStyle(color: Colors.red[700])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(WidgetRef ref, bool selectedTab) {
    return Row(
      children: [
        _buildTabButton(
          label: 'INGRESO',
          isSelected: !selectedTab,
          color: Colors.green,
          onTap: () => ref.read(selectedTabProvider.notifier).state = false,
        ),
        _buildTabButton(
          label: 'EGRESO',
          isSelected: selectedTab,
          color: Colors.red,
          onTap: () => ref.read(selectedTabProvider.notifier).state = true,
        ),
      ],
    );
  }

  Widget _buildCategoryList(bool isExpenseTab, Map<String, double> ingresos,
      Map<String, double> egresos) {
    final data = isExpenseTab ? egresos : ingresos;

    return data.isEmpty
        ? _buildEmptyState()
        : ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = data.keys.elementAt(index);
              final amount = data.values.elementAt(index);

              return ListTile(
                title: Text(category),
                trailing: Text(
                  formatCurrency(amount),
                  style: TextStyle(
                    color: isExpenseTab ? Colors.red[700] : Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => onCategoryTap?.call(category, isExpenseTab),
              );
            },
          );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha:0.15) : Colors.grey[100],
            border: Border(
              bottom: BorderSide(
                color: isSelected ? color : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No hay transacciones en este período',
        style: TextStyle(color: Colors.grey[600], fontSize: 16),
      ),
    );
  }

 String formatCurrency(double value) {
      final formatter = NumberFormat.decimalPattern('es_CO');
      return '\$${formatter.format(value)}';
    }
}
