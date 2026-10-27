import 'package:flutter/material.dart';
import 'package:finances/core/data/providers/portafolio_provider.dart';
import 'package:finances/utils/category_color_generator.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/screens/portafolio/portafolio_detail_screen.dart';
import 'package:finances/presentations/theme/theme.dart';

/// Tarjeta individual para mostrar un portafolio en listas y cuadrículas responsive
class PortfolioItemCard extends StatelessWidget {
  final PortafolioItemState item;
  final double totalPortfolioValueCOP;
  final VoidCallback onDelete;

  const PortfolioItemCard({
    super.key,
    required this.item,
    required this.totalPortfolioValueCOP,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final portafolio = item.portafolio;
    final color = CategoryColorGenerator.getColor(portafolio.id);
    final percentage = totalPortfolioValueCOP > 0
        ? (item.totalValueCOP / totalPortfolioValueCOP * 100)
        : 0.0;

    return Semantics(
      label: 'Portafolio ${portafolio.nombre}, total ${UIHelpers.formatCurrency(item.totalValueCOP)}',
      button: true,
      child: Material(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PortafolioDetailScreen(portafolio: portafolio),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
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
                // Cabecera: Avatar + Nombre + Botón Eliminar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
                      ),
                      child: Icon(Icons.folder_rounded, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            portafolio.nombre,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.isDarkMode
                                  ? context.colors.onSurface
                                  : const Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (portafolio.nota.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              portafolio.nota,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.isDarkMode
                                    ? context.colors.onSurfaceVariant
                                    : const Color(0xFF6B7280),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Botón de eliminar con área táctil accesible WCAG (48x48)
                    Semantics(
                      label: 'Eliminar portafolio ${portafolio.nombre}',
                      button: true,
                      child: IconButton(
                        iconSize: 22,
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        tooltip: PortafolioStrings.eliminarPortafolioTooltip,
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Valor total y porcentaje de participación
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          PortafolioStrings.valorTotalLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: context.isDarkMode
                                ? context.colors.onSurfaceVariant
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          UIHelpers.formatCurrency(item.totalValueCOP),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.isDarkMode
                                ? context.colors.primary
                                : const Color(0xFF003366),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pie_chart_outline_rounded, size: 13, color: color),
                          const SizedBox(width: 4),
                          Text(
                            UIHelpers.formatPercentage(percentage),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
