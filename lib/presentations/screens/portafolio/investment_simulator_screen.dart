import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/core/data/providers/portafolio_provider.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/presentations/screens/portafolio/widgets/simulator/simulator_models.dart';
import 'package:finances/presentations/screens/portafolio/widgets/simulator/simulator_result_hero_card.dart';
import 'package:finances/presentations/screens/portafolio/widgets/simulator/simulator_trm_sensitivity_card.dart';
import 'package:finances/presentations/screens/portafolio/widgets/simulator/simulator_share_helper.dart';
import 'package:finances/presentations/screens/portafolio/widgets/simulator/simulator_form_panel.dart';

export 'package:finances/presentations/screens/portafolio/widgets/simulator/simulator_models.dart';

class InvestmentSimulatorScreen extends ConsumerStatefulWidget {
  final double? initialCapital;
  final double? initialRateEA;
  final int? initialPlazoMeses;
  final bool initialIsRecurring;
  final String? investmentTitle;
  final String? currency;
  final bool? hasForeignCurrency;

  const InvestmentSimulatorScreen({
    super.key,
    this.initialCapital,
    this.initialRateEA,
    this.initialPlazoMeses,
    this.initialIsRecurring = false,
    this.investmentTitle,
    this.currency,
    this.hasForeignCurrency,
  });

  @override
  ConsumerState<InvestmentSimulatorScreen> createState() =>
      _InvestmentSimulatorScreenState();
}

class _InvestmentSimulatorScreenState
    extends ConsumerState<InvestmentSimulatorScreen> {
  final _capitalController = TextEditingController();
  final _aporteController = TextEditingController();

  late double _tasaEA;
  late int _plazoMeses;
  late bool _esAporteRecurrente;
  late String _selectedCurrency;
  late bool _enableTrmSensitivity;
  double? _simulatedTrm;
  int? _selectedPresetIndex;

  final List<int> _plazosRapidos = [6, 12, 24, 36, 60];

  @override
  void initState() {
    super.initState();

    final inputCurrency = (widget.currency ?? 'COP').toUpperCase();
    _selectedCurrency = (inputCurrency == 'USD' || inputCurrency == 'EUR')
        ? inputCurrency
        : 'COP';

    _enableTrmSensitivity =
        (widget.hasForeignCurrency == true) || (_selectedCurrency != 'COP');

    final capital = widget.initialCapital ??
        (_selectedCurrency == 'COP' ? 1000000.0 : 1000.0);
    _capitalController.text = UIHelpers.formatDecimal(capital.round());

    final aporte = widget.initialIsRecurring
        ? capital
        : (_selectedCurrency == 'COP' ? 100000.0 : 1000.0);
    _aporteController.text = UIHelpers.formatDecimal(aporte.round());

    _tasaEA = widget.initialRateEA ?? 10.5;
    _plazoMeses = widget.initialPlazoMeses ?? 12;
    _esAporteRecurrente = widget.initialIsRecurring;

    _updateSelectedPresetIndex();

    _capitalController.addListener(() => setState(() {}));
    _aporteController.addListener(() => setState(() {}));
  }

  void _updateSelectedPresetIndex() {
    final idx = kRatePresets.indexWhere(
      (p) => (p.rateEA - _tasaEA).abs() < 0.05,
    );
    _selectedPresetIndex = idx != -1 ? idx : null;
  }

  @override
  void dispose() {
    _capitalController.dispose();
    _aporteController.dispose();
    super.dispose();
  }

  double _parseInput(TextEditingController controller) {
    final raw = controller.text;
    final clean = raw.replaceAll(RegExp(r'[^\d,]'), '').replaceAll('.', '');
    return double.tryParse(clean.replaceAll(',', '.')) ?? 0.0;
  }

  double _getBaseTrm(AsyncValue ratesAsync) {
    if (_selectedCurrency == 'EUR') {
      return ratesAsync.value?.eurToCop ?? 4500.0;
    }
    return ratesAsync.value?.usdToCop ?? 4150.0;
  }

  void _triggerShare({
    required double capitalInicial,
    required double aporteMensual,
    required double balanceMoneda,
    required double capitalAportadoMoneda,
    required double gananciaInteresesMoneda,
    required double valorFinalCOP,
    required double capitalAportadoCOP,
    required double gananciaInteresesCOP,
    required double impactoCambiarioCOP,
    required double baseTrm,
    required double simulatedTrm,
    required double trmDiffPct,
    required double rendimientoTotalPorcentaje,
  }) {
    SimulatorShareHelper.share(
      context: context,
      title: widget.investmentTitle,
      selectedCurrency: _selectedCurrency,
      hasForeignCurrency: _selectedCurrency != 'COP' && _enableTrmSensitivity,
      capitalInicial: capitalInicial,
      aporteMensual: aporteMensual,
      esAporteRecurrente: _esAporteRecurrente,
      plazoMeses: _plazoMeses,
      tasaEA: _tasaEA,
      balanceMoneda: balanceMoneda,
      capitalAportadoMoneda: capitalAportadoMoneda,
      gananciaInteresesMoneda: gananciaInteresesMoneda,
      valorFinalCOP: valorFinalCOP,
      capitalAportadoCOP: capitalAportadoCOP,
      gananciaInteresesCOP: gananciaInteresesCOP,
      impactoCambiarioCOP: impactoCambiarioCOP,
      baseTrm: baseTrm,
      simulatedTrm: simulatedTrm,
      trmDiffPct: trmDiffPct,
      rendimientoTotalPorcentaje: rendimientoTotalPorcentaje,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(exchangeRatesStateProvider);
    final baseTrm = _getBaseTrm(ratesAsync);
    final simulatedTrm = _simulatedTrm ?? baseTrm;
    final trmDiffPct = baseTrm > 0 ? ((simulatedTrm - baseTrm) / baseTrm) * 100.0 : 0.0;

    final capitalInicial = _parseInput(_capitalController);
    final aporteMensual =
        _esAporteRecurrente ? _parseInput(_aporteController) : 0.0;

    // Cálculo financiero de interés compuesto: i_m = (1 + EA)^(1/12) - 1
    final tasaDecimalEA = _tasaEA / 100.0;
    final tasaMensual = pow(1.0 + tasaDecimalEA, 1.0 / 12.0) - 1.0;

    double balanceMoneda = capitalInicial;
    double capitalAportadoMoneda = capitalInicial;

    for (int m = 1; m <= _plazoMeses; m++) {
      balanceMoneda = balanceMoneda * (1.0 + tasaMensual) + aporteMensual;
      capitalAportadoMoneda += aporteMensual;
    }

    final gananciaInteresesMoneda =
        max(0.0, balanceMoneda - capitalAportadoMoneda);

    final bool hasForeign = _selectedCurrency != 'COP' && _enableTrmSensitivity;

    final double valorFinalCOP;
    final double capitalAportadoCOP;
    final double gananciaInteresesCOP;
    final double impactoCambiarioCOP;

    if (hasForeign) {
      valorFinalCOP = balanceMoneda * simulatedTrm;
      capitalAportadoCOP = capitalAportadoMoneda * baseTrm;
      gananciaInteresesCOP = gananciaInteresesMoneda * baseTrm;
      impactoCambiarioCOP = (balanceMoneda * simulatedTrm) - (balanceMoneda * baseTrm);
    } else {
      valorFinalCOP = balanceMoneda;
      capitalAportadoCOP = capitalAportadoMoneda;
      gananciaInteresesCOP = gananciaInteresesMoneda;
      impactoCambiarioCOP = 0.0;
    }

    final rendimientoTotalPorcentaje = capitalAportadoCOP > 0
        ? ((valorFinalCOP - capitalAportadoCOP) / capitalAportadoCOP) * 100.0
        : 0.0;

    return Scaffold(
      backgroundColor: context.scaffoldBgColor,
      appBar: AppBarFinances(
        title: widget.investmentTitle != null
            ? PortafolioStrings.simuladorTitleWithAsset(widget.investmentTitle!)
            : PortafolioStrings.simuladorTitle,
        showProfileIcon: false,
        actions: [
          Semantics(
            label: PortafolioStrings.compartirExportarBtn,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              tooltip: PortafolioStrings.compartirExportarTooltip,
              onPressed: () => _triggerShare(
                capitalInicial: capitalInicial,
                aporteMensual: aporteMensual,
                balanceMoneda: balanceMoneda,
                capitalAportadoMoneda: capitalAportadoMoneda,
                gananciaInteresesMoneda: gananciaInteresesMoneda,
                valorFinalCOP: valorFinalCOP,
                capitalAportadoCOP: capitalAportadoCOP,
                gananciaInteresesCOP: gananciaInteresesCOP,
                impactoCambiarioCOP: impactoCambiarioCOP,
                baseTrm: baseTrm,
                simulatedTrm: simulatedTrm,
                trmDiffPct: trmDiffPct,
                rendimientoTotalPorcentaje: rendimientoTotalPorcentaje,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Tarjeta Resumen Hero
                SimulatorResultHeroCard(
                  valorFinalCOP: valorFinalCOP,
                  balanceMoneda: balanceMoneda,
                  capitalInvertidoCOP: capitalAportadoCOP,
                  gananciaInteresesCOP: gananciaInteresesCOP,
                  impactoCambiarioCOP: impactoCambiarioCOP,
                  rendimientoPorcentaje: rendimientoTotalPorcentaje,
                  hasForeignCurrency: hasForeign,
                  trmDiffPct: trmDiffPct,
                  plazoMeses: _plazoMeses,
                  selectedCurrency: _selectedCurrency,
                ),

                const SizedBox(height: 20),

                // 2. Tarjeta de Sensibilidad Cambiaria (si aplica)
                if (_selectedCurrency != 'COP' || _enableTrmSensitivity) ...[
                  SimulatorTrmSensitivityCard(
                    baseTrm: baseTrm,
                    simulatedTrm: simulatedTrm,
                    trmDiffPct: trmDiffPct,
                    impactoCambiarioCOP: impactoCambiarioCOP,
                    selectedCurrency: _selectedCurrency,
                    onTrmChanged: (newTrm) {
                      setState(() => _simulatedTrm = newTrm);
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // 3. Panel de Configuración de Parámetros
                SimulatorFormPanel(
                  capitalController: _capitalController,
                  aporteController: _aporteController,
                  selectedCurrency: _selectedCurrency,
                  onCurrencyChanged: (curr) {
                    setState(() {
                      _selectedCurrency = curr;
                      _enableTrmSensitivity = curr != 'COP';
                      _simulatedTrm = null;
                    });
                  },
                  esAporteRecurrente: _esAporteRecurrente,
                  onAporteRecurrenteChanged: (val) {
                    setState(() => _esAporteRecurrente = val);
                  },
                  tasaEA: _tasaEA,
                  selectedPresetIndex: _selectedPresetIndex,
                  onTasaChanged: (val) {
                    setState(() {
                      _tasaEA = val;
                      _updateSelectedPresetIndex();
                    });
                  },
                  onPresetSelected: (index, rate) {
                    setState(() {
                      _tasaEA = rate;
                      _selectedPresetIndex = index;
                    });
                  },
                  plazoMeses: _plazoMeses,
                  onPlazoChanged: (val) {
                    setState(() => _plazoMeses = val);
                  },
                  plazosRapidos: _plazosRapidos,
                ),

                const SizedBox(height: 24),

                // 4. Botón Inferior para Exportar / Compartir
                Semantics(
                  label: PortafolioStrings.compartirExportarBtn,
                  button: true,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: context.colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: const Text(
                      PortafolioStrings.compartirExportarBtn,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    onPressed: () => _triggerShare(
                      capitalInicial: capitalInicial,
                      aporteMensual: aporteMensual,
                      balanceMoneda: balanceMoneda,
                      capitalAportadoMoneda: capitalAportadoMoneda,
                      gananciaInteresesMoneda: gananciaInteresesMoneda,
                      valorFinalCOP: valorFinalCOP,
                      capitalAportadoCOP: capitalAportadoCOP,
                      gananciaInteresesCOP: gananciaInteresesCOP,
                      impactoCambiarioCOP: impactoCambiarioCOP,
                      baseTrm: baseTrm,
                      simulatedTrm: simulatedTrm,
                      trmDiffPct: trmDiffPct,
                      rendimientoTotalPorcentaje: rendimientoTotalPorcentaje,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
