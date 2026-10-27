import 'dart:math';
import 'package:flutter/material.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/theme/theme.dart';

/// Tarjeta principal Hero con el valor futuro proyectado, gráfica de proporción y desglose de métricas
class SimulatorResultHeroCard extends StatelessWidget {
  final double valorFinalCOP;
  final double balanceMoneda;
  final double capitalInvertidoCOP;
  final double gananciaInteresesCOP;
  final double impactoCambiarioCOP;
  final double rendimientoPorcentaje;
  final bool hasForeignCurrency;
  final double trmDiffPct;
  final int plazoMeses;
  final String selectedCurrency;

  const SimulatorResultHeroCard({
    super.key,
    required this.valorFinalCOP,
    required this.balanceMoneda,
    required this.capitalInvertidoCOP,
    required this.gananciaInteresesCOP,
    required this.impactoCambiarioCOP,
    required this.rendimientoPorcentaje,
    required this.hasForeignCurrency,
    required this.trmDiffPct,
    required this.plazoMeses,
    required this.selectedCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final cardBg = isDark ? context.colors.surfaceContainer : Colors.white;

    final totalGananciaTotal = max(0.0, valorFinalCOP - capitalInvertidoCOP);
    final ratioGanancia = valorFinalCOP > 0
        ? (totalGananciaTotal / valorFinalCOP).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.colors.primary.withAlpha(40),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withAlpha(isDark ? 30 : 20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PortafolioStrings.valorFuturoProyectado,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      PortafolioStrings.plazoMesesYAnos(plazoMeses),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onSurfaceVariant.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (rendimientoPorcentaje >= 0 ? Colors.green : Colors.red)
                      .withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  UIHelpers.formatPercentage(rendimientoPorcentaje, includeSign: true),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: rendimientoPorcentaje >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Monto gigante proyectado en COP
          Text(
            UIHelpers.formatCurrency(valorFinalCOP),
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: context.colors.onSurface,
              letterSpacing: -0.8,
            ),
          ),

          // Subtítulo con el valor en moneda extranjera si aplica
          if (hasForeignCurrency) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  UIHelpers.formatForeignCurrency(balanceMoneda, selectedCurrency),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                if (trmDiffPct.abs() > 0.1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (trmDiffPct >= 0 ? Colors.green : Colors.amber).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      PortafolioStrings.trmBadge(trmDiffPct),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: trmDiffPct >= 0 ? Colors.green : Colors.amber[800],
                      ),
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 18),

          // Barra gráfica comparativa
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: ((1.0 - ratioGanancia) * 100).round().clamp(1, 100),
                  child: Container(
                    height: 10,
                    color: context.colors.primary,
                  ),
                ),
                Expanded(
                  flex: (ratioGanancia * 100).round().clamp(1, 100),
                  child: Container(
                    height: 10,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Desglose de métricas
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  icon: Icons.savings_outlined,
                  iconColor: context.colors.primary,
                  title: PortafolioStrings.capitalAportadoLabel,
                  value: UIHelpers.formatCurrency(capitalInvertidoCOP),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricItem(
                  context,
                  icon: Icons.trending_up_rounded,
                  iconColor: Colors.green,
                  title: PortafolioStrings.gananciaInteresesLabel,
                  value: UIHelpers.formatCurrency(gananciaInteresesCOP),
                  valueColor: Colors.green,
                ),
              ),
            ],
          ),

          // Métrica extra si hay efecto cambiario
          if (hasForeignCurrency && impactoCambiarioCOP.abs() > 100) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (impactoCambiarioCOP >= 0 ? Colors.green : Colors.orange)
                    .withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (impactoCambiarioCOP >= 0 ? Colors.green : Colors.orange)
                      .withAlpha(50),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.currency_exchange_rounded,
                    size: 18,
                    color: impactoCambiarioCOP >= 0 ? Colors.green : Colors.orange[800],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      PortafolioStrings.efectoCambiarioBadge(trmDiffPct),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${impactoCambiarioCOP >= 0 ? '+' : ''}${UIHelpers.formatCurrency(impactoCambiarioCOP)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: impactoCambiarioCOP >= 0 ? Colors.green : Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.colors.surfaceContainerHigh
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.outlineVariant.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? context.colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
