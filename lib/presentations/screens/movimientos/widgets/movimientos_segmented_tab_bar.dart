import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finances/presentations/theme/theme.dart';

class MovimientosSegmentedTabBar extends StatelessWidget {
  final TabController tabController;
  final int gastosCount;
  final int ingresosCount;

  const MovimientosSegmentedTabBar({
    super.key,
    required this.tabController,
    this.gastosCount = 0,
    this.ingresosCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, child) {
        final currentIndex = tabController.index;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF161B22)
                : Colors.grey.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Pestaña 0: Gastos
              Expanded(
                child: _buildTabItem(
                  context: context,
                  index: 0,
                  isSelected: currentIndex == 0,
                  label: 'Gastos',
                  icon: Icons.trending_down_rounded,
                  count: gastosCount,
                  activeColor: const Color(0xFFEF5350),
                ),
              ),
              const SizedBox(width: 4),
              // Pestaña 1: Ingresos
              Expanded(
                child: _buildTabItem(
                  context: context,
                  index: 1,
                  isSelected: currentIndex == 1,
                  label: 'Ingresos',
                  icon: Icons.trending_up_rounded,
                  count: ingresosCount,
                  activeColor: const Color(0xFF26A69A),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabItem({
    required BuildContext context,
    required int index,
    required bool isSelected,
    required String label,
    required IconData icon,
    required int count,
    required Color activeColor,
  }) {
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: () {
        if (tabController.index != index) {
          HapticFeedback.selectionClick();
        }
        tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? activeColor.withValues(alpha: 0.18) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
          border: isSelected
              ? Border.all(
                  color: isDark
                      ? activeColor.withValues(alpha: 0.4)
                      : activeColor.withValues(alpha: 0.25),
                  width: 1.5,
                )
              : null,
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected
                  ? activeColor
                  : context.colors.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? activeColor
                    : context.colors.onSurface.withValues(alpha: 0.65),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.2)
                      : context.colors.onSurface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? activeColor
                        : context.colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
