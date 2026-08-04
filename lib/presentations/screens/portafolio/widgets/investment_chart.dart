import 'package:flutter/material.dart';
import 'package:finances/core/data/providers/investment_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';

class InvestmentChart extends StatefulWidget {
  final List<InvestmentItemState> investments;
  const InvestmentChart({super.key, required this.investments});

  @override
  State<InvestmentChart> createState() => _InvestmentChartState();
}

class _InvestmentChartState extends State<InvestmentChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.investments.fold(0.0, (sum, item) => sum + item.convertedValueCOP);
    if (total <= 0) return const SizedBox.shrink();

    // Calcular valor consolidado de inversiones pequeñas (<1%)
    double otrosValue = 0.0;
    for (final item in widget.investments) {
      if (item.convertedValueCOP > 0) {
        final share = item.convertedValueCOP / total;
        if (share < 0.01) {
          otrosValue += item.convertedValueCOP;
        }
      }
    }

    final hasSelection = _touchedIndex >= 0 && _touchedIndex < widget.investments.length;
    final selectedItem = hasSelection ? widget.investments[_touchedIndex] : null;
    final isOtrosSelected = _touchedIndex == widget.investments.length && otrosValue > 0.0;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: context.cardBgColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('Distribución de Inversiones',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: context.isDarkMode ? context.colors.onSurface : Colors.blueGrey)),
              const SizedBox(height: 8),
              Text('Total: ${UIHelpers.formatCurrency(total)}',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.isDarkMode ? context.colors.onSurface : Colors.black87)),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 1.3,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(PieChartData(
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
                      sections: _chartSections(total, otrosValue),
                      centerSpaceRadius: 55,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                    )),
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
                              ? (_touchedIndex == widget.investments.length
                                  ? '${((otrosValue / total) * 100).toStringAsFixed(1)}%'
                                  : (_touchedIndex < widget.investments.length
                                      ? '${((widget.investments[_touchedIndex].convertedValueCOP / total) * 100).toStringAsFixed(1)}%'
                                      : '0.0%'))
                              : UIHelpers.formatCurrency(total),
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

              // Animación de detalle interactivo
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: selectedItem != null
                    ? Container(
                        key: ValueKey(selectedItem.investment.id),
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _generateColor(selectedItem.investment.activo).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _generateColor(selectedItem.investment.activo).withOpacity(0.3),
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
                                    color: _generateColor(selectedItem.investment.activo),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    selectedItem.investment.descripcion,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _generateColor(selectedItem.investment.activo),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(selectedItem.convertedValueCOP / total * 100).toStringAsFixed(1)}%',
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
                              'Origen: ${selectedItem.investment.origen} | Tipo: ${selectedItem.investment.activo}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Monto: ${UIHelpers.formatCurrency(selectedItem.investment.invMensual)} ${selectedItem.investment.moneda}' +
                                  (selectedItem.investment.moneda.toUpperCase() != 'COP'
                                      ? ' (≈ ${UIHelpers.formatCurrency(selectedItem.convertedValueCOP)} COP)'
                                      : ''),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      )
                    : isOtrosSelected
                        ? Container(
                            key: const ValueKey('otros_inv_selection'),
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
                                        'Otras Inversiones Pequeñas',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${(otrosValue / total * 100).toStringAsFixed(1)}%',
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
                                  'Agrupa inversiones individuales con participación menor al 1% del total del portafolio.',
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
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _chartSections(double total, double otrosValue) {
    final List<PieChartSectionData> sections = [];

    for (int i = 0; i < widget.investments.length; i++) {
      final item = widget.investments[i];
      if (item.convertedValueCOP <= 0) continue;

      final share = item.convertedValueCOP / total;
      if (share < 0.01) {
        continue; // Agrupados
      }

      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 22.0 : 16.0;
      final investment = item.investment;

      sections.add(PieChartSectionData(
        color: _generateColor(investment.activo),
        value: item.convertedValueCOP,
        title: '', // Sin texto sobre las rebanadas para evitar amontonamiento visual
        radius: radius,
      ));
    }

    if (otrosValue > 0.0) {
      final isTouched = _touchedIndex == widget.investments.length;
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


  Color _generateColor(String key) {
    final hash = key.hashCode;
    return Color.fromARGB(255, hash % 256, (hash * 2) % 256, (hash * 3) % 256);
  }
}


