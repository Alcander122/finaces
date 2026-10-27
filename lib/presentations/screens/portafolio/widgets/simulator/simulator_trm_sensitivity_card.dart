import 'package:flutter/material.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/theme/theme.dart';

/// Tarjeta de control interactivo de Sensibilidad Cambiaria (Dólar / TRM simulada)
class SimulatorTrmSensitivityCard extends StatelessWidget {
  final double baseTrm;
  final double simulatedTrm;
  final double trmDiffPct;
  final double impactoCambiarioCOP;
  final String selectedCurrency;
  final ValueChanged<double> onTrmChanged;

  const SimulatorTrmSensitivityCard({
    super.key,
    required this.baseTrm,
    required this.simulatedTrm,
    required this.trmDiffPct,
    required this.impactoCambiarioCOP,
    required this.selectedCurrency,
    required this.onTrmChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = context.isDarkMode
        ? context.colors.surfaceContainer
        : Colors.white;

    final minTrm = (baseTrm * 0.70).roundToDouble();
    final maxTrm = (baseTrm * 1.45).roundToDouble();

    // Escenarios predefinidos de sensibilidad TRM
    final trmScenarios = [
      {'label': 'Base Actual', 'factor': 1.0},
      {'label': 'COP Fuerte (-10%)', 'factor': 0.90},
      {'label': 'Alza Moderada (+5%)', 'factor': 1.05},
      {'label': 'Devaluación (+15%)', 'factor': 1.15},
      {'label': 'Escenario Alto (+25%)', 'factor': 1.25},
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.colors.primary.withAlpha(50),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.currency_exchange_rounded,
                  color: context.colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PortafolioStrings.sensibilidadCambiariaTitle(selectedCurrency),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                    ),
                    Text(
                      PortafolioStrings.trmBaseOficialLabel(UIHelpers.formatCurrency(baseTrm)),
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (trmDiffPct >= 0 ? Colors.green : Colors.amber).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (trmDiffPct >= 0 ? Colors.green : Colors.amber).withAlpha(60),
                  ),
                ),
                child: Text(
                  UIHelpers.formatPercentage(trmDiffPct, includeSign: true),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: trmDiffPct >= 0 ? Colors.green : Colors.amber[800],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Valor destacado de la TRM simulada
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? context.colors.surfaceContainerHigh
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  PortafolioStrings.trmSimuladaProyectadaLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  UIHelpers.formatCurrency(simulatedTrm),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Chips de escenarios rápidos
          Text(
            PortafolioStrings.escenariosMercadoLabel,
            style: TextStyle(
              fontSize: 11,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: trmScenarios.map((sc) {
              final targetTrm = (baseTrm * (sc['factor'] as double)).roundToDouble();
              final isSelected = (simulatedTrm - targetTrm).abs() < 15;

              return ChoiceChip(
                label: Text(
                  sc['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : context.colors.onSurface,
                  ),
                ),
                selected: isSelected,
                selectedColor: context.colors.primary,
                backgroundColor: context.isDarkMode
                    ? context.colors.surfaceContainerHigh
                    : const Color(0xFFF8FAFC),
                onSelected: (selected) {
                  if (selected) {
                    onTrmChanged(targetTrm);
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Slider interactivo de TRM
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: context.colors.primary,
              thumbColor: context.colors.primary,
              overlayColor: context.colors.primary.withAlpha(30),
              trackHeight: 6,
            ),
            child: Slider(
              value: simulatedTrm.clamp(minTrm, maxTrm),
              min: minTrm,
              max: maxTrm,
              divisions: 150,
              label: UIHelpers.formatCurrency(simulatedTrm),
              onChanged: (val) {
                onTrmChanged(val.roundToDouble());
              },
            ),
          ),

          // Explicación didáctica del escenario
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              trmDiffPct >= 0
                  ? PortafolioStrings.trmApreciacionMsg(
                      selectedCurrency,
                      UIHelpers.formatCurrency(simulatedTrm),
                      UIHelpers.formatCurrency(impactoCambiarioCOP.abs()),
                    )
                  : PortafolioStrings.trmAmortiguacionMsg(
                      UIHelpers.formatCurrency(simulatedTrm),
                      UIHelpers.formatCurrency(impactoCambiarioCOP.abs()),
                    ),
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
