import 'package:finances/core/data/providers/category_summary_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/theme/theme.dart';

final selectedTabProvider = StateProvider<bool>((ref) => false);

class CategorySummary extends ConsumerWidget {
  final void Function(String category, bool isExpense)? onCategoryTap;

  const CategorySummary({super.key, this.onCategoryTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);
    final summaryAsync = ref.watch(ingresosEgresosCategoryStreamProvider);

    return Column(
      children: [
        _buildTabSelector(context, ref, selectedTab),
        summaryAsync.when(
          data: (summaryData) => _buildCategoryList(
            context,
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
      ],
    );
  }

  Widget _buildTabSelector(BuildContext context, WidgetRef ref, bool selectedTab) {
    return Row(
      children: [
        _buildTabButton(
          context: context,
          label: 'INGRESO',
          isSelected: !selectedTab,
          color: Colors.green,
          onTap: () => ref.read(selectedTabProvider.notifier).state = false,
        ),
        _buildTabButton(
          context: context,
          label: 'EGRESO',
          isSelected: selectedTab,
          color: Colors.red,
          onTap: () => ref.read(selectedTabProvider.notifier).state = true,
        ),
      ],
    );
  }

  Widget _buildCategoryList(BuildContext context, bool isExpenseTab, Map<String, double> ingresos,
      Map<String, double> egresos) {
    final data = isExpenseTab ? egresos : ingresos;

    return data.isEmpty
        ? _buildEmptyState(context)
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: data.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: context.isDarkMode ? Colors.grey[800] : Colors.grey[200]),
            itemBuilder: (context, index) {
              final category = data.keys.elementAt(index);
              final amount = data.values.elementAt(index);

              return ListTile(
                title: Text(
                  category,
                  style: TextStyle(color: context.isDarkMode ? Colors.white : Colors.black87),
                ),
                trailing: Text(
                  UIHelpers.formatCurrency(amount),
                  style: TextStyle(
                    color: isExpenseTab 
                        ? (context.isDarkMode ? Colors.redAccent : Colors.red[700])
                        : (context.isDarkMode ? Colors.greenAccent : Colors.green[700]),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => onCategoryTap?.call(category, isExpenseTab),
              );
            },
          );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? color.withValues(alpha: isDark ? 0.25 : 0.15) 
                : (isDark ? const Color(0xFF0F172A) : Colors.grey[100]),
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
              color: isSelected ? color : (isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'No hay transacciones en este período',
          style: TextStyle(color: context.isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 16),
        ),
      ),
    );
  }
}
