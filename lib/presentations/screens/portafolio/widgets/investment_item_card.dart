import 'package:flutter/material.dart';
import 'package:finances/core/data/models/portafolio_model.dart';
import 'package:finances/core/data/providers/investment_provider.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/screens/portafolio/investment_form_screen.dart';
import 'package:finances/presentations/screens/portafolio/investment_simulator_screen.dart';
import 'package:finances/presentations/theme/theme.dart';

/// Tarjeta individual para mostrar una inversión en el detalle del portafolio
class InvestmentItemCard extends StatelessWidget {
  final Portafolio portafolio;
  final InvestmentItemState item;
  final double totalCOP;
  final VoidCallback onDelete;

  const InvestmentItemCard({
    super.key,
    required this.portafolio,
    required this.item,
    required this.totalCOP,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final investment = item.investment;
    final isForeign = investment.moneda.toUpperCase() != 'COP';
    final share = totalCOP > 0 ? (item.convertedValueCOP / totalCOP * 100) : 0.0;

    return Semantics(
      label:
          'Inversión ${investment.descripcion}, ${UIHelpers.formatCurrencyAmount(investment.invMensual, currency: investment.moneda)}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDarkMode ? 0.25 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Fila superior: Tipo de Activo + Moneda + Acciones
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    investment.activo.isNotEmpty ? investment.activo : 'General',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: context.colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    investment.moneda.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                const Spacer(),
                // Botón simular inversión
                Semantics(
                  label: 'Simular proyección de inversión ${investment.descripcion}',
                  button: true,
                  child: IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: Icon(Icons.auto_graph_rounded, color: context.colors.primary),
                    tooltip: PortafolioStrings.simularProyeccionTooltip,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InvestmentSimulatorScreen(
                          initialCapital: investment.moneda.toUpperCase() == 'COP'
                              ? item.convertedValueCOP
                              : investment.invMensual,
                          initialRateEA: investment.rendimientoEstimadoEA ?? 10.5,
                          initialPlazoMeses: investment.plazoMeses ?? 12,
                          initialIsRecurring: investment.esAporteRecurrente,
                          investmentTitle: investment.descripcion,
                          currency: investment.moneda.toUpperCase(),
                          hasForeignCurrency:
                              investment.moneda.toUpperCase() != 'COP',
                        ),
                      ),
                    ),
                  ),
                ),
                // Botón editar accesible
                Semantics(
                  label: 'Editar inversión ${investment.descripcion}',
                  button: true,
                  child: IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: Icon(Icons.edit_outlined, color: context.colors.primary),
                    tooltip: PortafolioStrings.editarInversionTooltip,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InvestmentFormScreen(
                          userId: portafolio.userId,
                          portafolioId: portafolio.id,
                          investment: investment,
                        ),
                      ),
                    ),
                  ),
                ),
                // Botón eliminar accesible
                Semantics(
                  label: 'Eliminar inversión ${investment.descripcion}',
                  button: true,
                  child: IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    tooltip: PortafolioStrings.eliminarInversionTooltip,
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Descripción
            Text(
              investment.descripcion,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: context.isDarkMode ? context.colors.onSurface : const Color(0xFF111827),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (investment.rendimientoEstimadoEA != null || investment.plazoMeses != null) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (investment.rendimientoEstimadoEA != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${investment.rendimientoEstimadoEA!.toStringAsFixed(1)}% E.A.',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  if (investment.plazoMeses != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${investment.plazoMeses} meses',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.colors.primary),
                      ),
                    ),
                  if (investment.esAporteRecurrente)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Recurrente',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),

            // Monto principal y convertido
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      UIHelpers.formatCurrencyAmount(investment.invMensual, currency: investment.moneda),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.isDarkMode ? context.colors.onSurface : const Color(0xFF1F2937),
                      ),
                    ),
                    if (isForeign) ...[
                      const SizedBox(height: 2),
                      Text(
                        '≈ ${UIHelpers.formatCurrency(item.convertedValueCOP)} COP',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[context.isDarkMode ? 400 : 700],
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    UIHelpers.formatPercentage(share),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: context.isDarkMode ? context.colors.onSurfaceVariant : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
