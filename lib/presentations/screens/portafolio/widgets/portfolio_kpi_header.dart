import 'package:flutter/material.dart';
import 'package:finances/core/data/models/portafolio_model.dart';
import 'package:finances/core/data/providers/portafolio_provider.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/theme/theme.dart';

class _KpiData {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _KpiData({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });
}

/// Encabezado con 3 tarjetas de métricas clave (Patrimonio Total, Portafolios y Activos)
class PortfolioKpiHeader extends StatelessWidget {
  final PortfolioDashboardState dashboardState;
  final bool isSmallScreen;

  const PortfolioKpiHeader({
    super.key,
    required this.dashboardState,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final kpis = [
      _KpiData(
        title: PortafolioStrings.kpiPatrimonioTotal,
        value: UIHelpers.formatCurrency(dashboardState.totalPortfolioValueCOP),
        icon: Icons.account_balance_rounded,
        accentColor: const Color(0xFF2E7D32),
      ),
      _KpiData(
        title: PortafolioStrings.kpiPortafolios,
        value: dashboardState.portfolioItems.length.toString(),
        icon: Icons.folder_special_rounded,
        accentColor: const Color(0xFF1976D2),
      ),
      _KpiData(
        title: PortafolioStrings.kpiActivosCartera,
        value: dashboardState.numberOfAssets.toString(),
        icon: Icons.pie_chart_rounded,
        accentColor: const Color(0xFFE65100),
      ),
    ];

    if (isSmallScreen) {
      return Column(
        children: kpis
            .map((kpi) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildKpiCard(context, kpi),
                ))
            .toList(),
      );
    }

    return Row(
      children: kpis
          .map(
            (kpi) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _buildKpiCard(context, kpi),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildKpiCard(BuildContext context, _KpiData kpi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kpi.accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(kpi.icon, color: kpi.accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kpi.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.isDarkMode
                        ? context.colors.onSurfaceVariant
                        : const Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  kpi.value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.isDarkMode
                        ? context.colors.onSurface
                        : const Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de cabecera con el resumen patrimonial del portafolio en la pantalla de detalle
class PortfolioDetailHeaderCard extends StatelessWidget {
  final Portafolio portafolio;
  final double totalCOP;
  final int count;

  const PortfolioDetailHeaderCard({
    super.key,
    required this.portafolio,
    required this.totalCOP,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.folder_open_rounded, color: context.colors.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      portafolio.nombre,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.isDarkMode ? context.colors.onSurface : const Color(0xFF111827),
                      ),
                    ),
                    if (portafolio.descripcion != null && portafolio.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        portafolio.descripcion!,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.isDarkMode ? context.colors.onSurfaceVariant : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    PortafolioStrings.valorConsolidadoLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.isDarkMode ? context.colors.onSurfaceVariant : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    UIHelpers.formatCurrency(totalCOP),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.isDarkMode ? context.colors.primary : const Color(0xFF003366),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.layers_rounded, size: 16, color: context.colors.primary),
                    const SizedBox(width: 6),
                    Text(
                      PortafolioStrings.inversionesBadge(count),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
