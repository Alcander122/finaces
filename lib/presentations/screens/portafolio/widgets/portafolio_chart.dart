import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finances/presentations/theme/theme.dart';
import '../../../../core/data/providers/portafolio_provider.dart';
import '../../../../utils/category_color_generator.dart';
import '../../../../core/data/utils/ui_helpers.dart';

class PortafolioChart extends StatefulWidget {
  final double totalValueCOP;
  final List<PortafolioItemState> portfolioItems;

  const PortafolioChart({
    super.key,
    required this.totalValueCOP,
    required this.portfolioItems,
  });

  @override
  State<PortafolioChart> createState() => _PortafolioChartState();
}

class _PortafolioChartState extends State<PortafolioChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.portfolioItems.isEmpty || widget.totalValueCOP <= 0) return const SizedBox.shrink();

    // Obtener item seleccionado para mostrar en el card dinámico
    // Calcular valor consolidado de portfolios pequeños (<1%)
    double otrosValue = 0.0;
    for (final item in widget.portfolioItems) {
      if (item.totalValueCOP > 0) {
        final share = item.totalValueCOP / widget.totalValueCOP;
        if (share < 0.01) {
          otrosValue += item.totalValueCOP;
        }
      }
    }

    final hasSelection = _touchedIndex >= 0 && _touchedIndex < widget.portfolioItems.length;
    final selectedItem = hasSelection ? widget.portfolioItems[_touchedIndex] : null;
    final isOtrosSelected = _touchedIndex == widget.portfolioItems.length && otrosValue > 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: context.cardBgColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Distribución del Portafolio',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.isDarkMode ? context.colors.onSurface : Colors.blueGrey,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${UIHelpers.formatCurrency(widget.totalValueCOP)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.isDarkMode ? context.colors.onSurface : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 1.3,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: _chartSections(otrosValue),
                        centerSpaceRadius: 55,
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _touchedIndex >= 0 ? 'Porcentaje' : 'Total',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: context.isDarkMode ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _touchedIndex >= 0
                              ? (_touchedIndex == widget.portfolioItems.length
                                  ? '${((otrosValue / widget.totalValueCOP) * 100).toStringAsFixed(1)}%'
                                  : (_touchedIndex < widget.portfolioItems.length
                                      ? '${((widget.portfolioItems[_touchedIndex].totalValueCOP / widget.totalValueCOP) * 100).toStringAsFixed(1)}%'
                                      : '0.0%'))
                              : UIHelpers.formatCurrency(widget.totalValueCOP),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: context.colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Animación fluida para mostrar detalles del sector seleccionado
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: selectedItem != null
                    ? Container(
                        key: ValueKey(selectedItem.portafolio.id),
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CategoryColorGenerator.getColor(selectedItem.portafolio.id).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CategoryColorGenerator.getColor(selectedItem.portafolio.id).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: CategoryColorGenerator.getColor(selectedItem.portafolio.id),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    selectedItem.portafolio.nombre,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: CategoryColorGenerator.getColor(selectedItem.portafolio.id),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(selectedItem.totalValueCOP / widget.totalValueCOP * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.blueGrey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Valor: ${UIHelpers.formatCurrency(selectedItem.totalValueCOP)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            if (selectedItem.portafolio.nota.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Nota: ${selectedItem.portafolio.nota}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ]
                          ],
                        ),
                      )
                    : isOtrosSelected
                        ? Container(
                            key: const ValueKey('otros_selection'),
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Otras Categorías Pequeñas',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${(otrosValue / widget.totalValueCOP * 100).toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.blueGrey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Valor Consolidado: ${UIHelpers.formatCurrency(otrosValue)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Agrupa portafolios individuales con participación menor al 1% del total.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const Text(
                            'Toca un sector del gráfico para ver detalles',
                            key: ValueKey('prompt'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
              ),
              const SizedBox(height: 16),
              _buildLeyenda(),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _chartSections(double otrosValue) {
    final List<PieChartSectionData> sections = [];

    for (int i = 0; i < widget.portfolioItems.length; i++) {
      final item = widget.portfolioItems[i];
      if (item.totalValueCOP <= 0) continue;

      final share = item.totalValueCOP / widget.totalValueCOP;
      if (share < 0.01) {
        continue; // Agrupados
      }

      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 22.0 : 16.0;

      sections.add(PieChartSectionData(
        color: CategoryColorGenerator.getColor(item.portafolio.id),
        value: item.totalValueCOP,
        title: '', // Sin texto sobre las rebanadas para evitar amontonamiento visual
        radius: radius,
      ));
    }

    if (otrosValue > 0.0) {
      final isTouched = _touchedIndex == widget.portfolioItems.length;
      final radius = isTouched ? 22.0 : 16.0;

      sections.add(PieChartSectionData(
        color: Colors.grey,
        value: otrosValue,
        title: '', // Sin texto sobre las rebanadas
        radius: radius,
      ));
    }

    return sections;
  }

  Widget _buildLeyenda() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: widget.portfolioItems.map((item) {
        final color = CategoryColorGenerator.getColor(item.portafolio.id);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              item.portafolio.nombre,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

}


