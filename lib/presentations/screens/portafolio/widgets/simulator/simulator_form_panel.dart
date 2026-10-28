import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/widgets/app_input_style.dart';
import 'package:finances/presentations/screens/portafolio/widgets/simulator/simulator_models.dart';

/// Formulario con los controles de capital, aportes recurrentes, tasa E.A. y plazos
class SimulatorFormPanel extends StatelessWidget {
  final TextEditingController capitalController;
  final TextEditingController aporteController;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final bool esAporteRecurrente;
  final ValueChanged<bool> onAporteRecurrenteChanged;
  final double tasaEA;
  final int? selectedPresetIndex;
  final ValueChanged<double> onTasaChanged;
  final void Function(int index, double rate) onPresetSelected;
  final int plazoMeses;
  final ValueChanged<int> onPlazoChanged;
  final List<int> plazosRapidos;

  const SimulatorFormPanel({
    super.key,
    required this.capitalController,
    required this.aporteController,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    required this.esAporteRecurrente,
    required this.onAporteRecurrenteChanged,
    required this.tasaEA,
    required this.selectedPresetIndex,
    required this.onTasaChanged,
    required this.onPresetSelected,
    required this.plazoMeses,
    required this.onPlazoChanged,
    required this.plazosRapidos,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = context.isDarkMode
        ? context.colors.surfaceContainer
        : Colors.white;

    final symbolMoneda = UIHelpers.formatCurrencySymbol(selectedCurrency);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.colors.outlineVariant.withAlpha(50),
        ),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  PortafolioStrings.configuracionSimulacionTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? context.colors.surfaceContainerHigh
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['COP', 'USD', 'EUR'].map((curr) {
                    final isSel = selectedCurrency == curr;
                    return GestureDetector(
                      onTap: () => onCurrencyChanged(curr),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel ? context.colors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          curr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel
                                ? Colors.white
                                : context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Capital Inicial
          TextFormField(
            controller: capitalController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              ThousandsSeparatorInputFormatter(),
            ],
            decoration: AppInputStyle.textField(
              label: PortafolioStrings.capitalInicialLabel(symbolMoneda),
              prefixIcon: Icon(
                selectedCurrency == 'EUR'
                    ? Icons.euro_rounded
                    : Icons.attach_money_rounded,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Aporte Recurrente Mensual
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              PortafolioStrings.aportesRecurrentesTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
            subtitle: Text(
              PortafolioStrings.aportesRecurrentesSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            value: esAporteRecurrente,
            onChanged: onAporteRecurrenteChanged,
          ),

          if (esAporteRecurrente) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: aporteController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
              decoration: AppInputStyle.textField(
                label: PortafolioStrings.aporteMensualLabel(symbolMoneda),
                prefixIcon: const Icon(Icons.add_card_rounded),
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // 3. Tasa de Rentabilidad y Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                PortafolioStrings.tasaEstimadaLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  PortafolioStrings.tasaEaBadge(tasaEA),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            PortafolioStrings.tasasReferenciaLabel,
            style: TextStyle(
              fontSize: 12,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(kRatePresets.length, (index) {
              final preset = kRatePresets[index];
              final isSelected = selectedPresetIndex == index;

              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      preset.icon,
                      size: 14,
                      color: isSelected ? Colors.white : context.colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      preset.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : context.colors.onSurface,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: context.colors.primary,
                backgroundColor: context.isDarkMode
                    ? context.colors.surfaceContainerHigh
                    : const Color(0xFFF1F5F9),
                side: BorderSide(
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.outlineVariant.withAlpha(60),
                ),
                onSelected: (selected) {
                  onPresetSelected(index, preset.rateEA);
                },
              );
            }),
          ),

          const SizedBox(height: 14),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: context.colors.primary,
              thumbColor: context.colors.primary,
              overlayColor: context.colors.primary.withAlpha(30),
              trackHeight: 6,
            ),
            child: Slider(
              value: tasaEA.clamp(1.0, 30.0),
              min: 1.0,
              max: 30.0,
              divisions: 290,
              label: PortafolioStrings.tasaEaBadge(tasaEA),
              onChanged: (val) {
                onTasaChanged(double.parse(val.toStringAsFixed(1)));
              },
            ),
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // 4. Plazo de la Inversión (Meses)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                PortafolioStrings.plazoInversionLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
              Text(
                PortafolioStrings.plazoDisplay(plazoMeses),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            children: plazosRapidos.map((meses) {
              final isSelected = plazoMeses == meses;
              final label = meses < 12
                  ? '$meses meses'
                  : '${meses ~/ 12} ${meses == 12 ? 'año' : 'años'}';

              return ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : context.colors.onSurface,
                  ),
                ),
                selected: isSelected,
                selectedColor: context.colors.primary,
                backgroundColor: context.isDarkMode
                    ? context.colors.surfaceContainerHigh
                    : const Color(0xFFF1F5F9),
                onSelected: (selected) {
                  if (selected) {
                    onPlazoChanged(meses);
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: context.colors.primary,
              thumbColor: context.colors.primary,
              trackHeight: 6,
            ),
            child: Slider(
              value: plazoMeses.toDouble().clamp(1.0, 120.0),
              min: 1.0,
              max: 120.0,
              divisions: 119,
              label: '$plazoMeses meses',
              onChanged: (val) {
                onPlazoChanged(val.round());
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Formateador para separar miles con puntos mientras el usuario escribe
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final cleanText = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final number = int.tryParse(cleanText) ?? 0;
    final formatted = UIHelpers.formatDecimal(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
