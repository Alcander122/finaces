import 'package:flutter/material.dart';

/// Preajuste de tasa de rentabilidad de referencia
class SimulatorRatePreset {
  final String label;
  final String subtitle;
  final double rateEA;
  final IconData icon;

  const SimulatorRatePreset({
    required this.label,
    required this.subtitle,
    required this.rateEA,
    required this.icon,
  });
}

/// Presets de referencia para Colombia y mercados globales
const List<SimulatorRatePreset> kRatePresets = [
  SimulatorRatePreset(
    label: 'CDT 9.8% E.A.',
    subtitle: 'CDT 90 días bancario',
    rateEA: 9.8,
    icon: Icons.account_balance_outlined,
  ),
  SimulatorRatePreset(
    label: 'CDT 360d 10.5% E.A.',
    subtitle: 'CDT a 1 año bancario',
    rateEA: 10.5,
    icon: Icons.verified_outlined,
  ),
  SimulatorRatePreset(
    label: 'FIC 9.0% E.A.',
    subtitle: 'Fondo de Inversión Colectiva',
    rateEA: 9.0,
    icon: Icons.pie_chart_outline_rounded,
  ),
  SimulatorRatePreset(
    label: 'S&P 500 11% E.A.',
    subtitle: 'Renta variable promedio anual',
    rateEA: 11.0,
    icon: Icons.trending_up_rounded,
  ),
];
