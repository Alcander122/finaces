import 'package:finances/core/data/models/investment_model.dart';
import 'package:finances/core/data/providers/investment_provider.dart';
import 'package:finances/core/data/providers/portafolio_provider.dart';
import 'package:finances/core/data/services/currency_service.dart';
import 'package:finances/core/data/utils/form_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/core/errors/handlers/db_error_handler.dart';
import 'package:finances/presentations/widgets/custom_form_container.dart';
import 'package:finances/presentations/widgets/app_input_style.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/theme/theme.dart';

class InvestmentFormScreen extends ConsumerStatefulWidget {
  final String userId;
  final String portafolioId;
  final Investment? investment;

  const InvestmentFormScreen({
    super.key,
    required this.userId,
    required this.portafolioId,
    this.investment,
  });

  @override
  ConsumerState<InvestmentFormScreen> createState() => _InvestmentFormScreenState();
}

class _InvestmentFormScreenState extends ConsumerState<InvestmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _rendimientoController = TextEditingController();
  final _plazoMesesController = TextEditingController();
  final _validator = FormValidator();

  bool _esAporteRecurrente = false;

  // === VALORES SELECCIONADOS ===
  late String _selectedMoneda;
  late String _selectedMes;
  late String _selectedOrigen;
  late String _selectedActivo;
  late String _selectedEstado;
  late DateTime _selectedFechaInversion;

  // === CONVERSIÓN DE MONEDA ===
  double _tasaConversion = 1.0;
  double _montoConvertido = 0.0;
  bool _isLoadingConversion = false;
  bool _isSaving = false;

  // === LISTAS DE OPCIONES ===
  late final List<String> _meses;

  final List<String> _origenes = [
    'Ahorros',
    'Salario',
    'Rendimientos',
    'Otros'
  ];

  @override
  void initState() {
    super.initState();

    // 1. Generar lista de meses capitalizados
    _meses = DateFormat.MMMM('es')
        .dateSymbols
        .MONTHS
        .map((mes) => mes[0].toUpperCase() + mes.substring(1).toLowerCase())
        .toList();

    // Listener DESPUÉS de inicializar
    _montoController.addListener(_updateConversion);

    // Conversión inicial DESPUÉS del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateConversion();
        _formKey.currentState?.validate();
      }
    });
    
    // 2. Inicializar todos los campos
    _initializeFields();
  }

  /// Inicializa todos los campos del formulario
  void _initializeFields() {
    final now = DateTime.now();

    // === MONEDA ===
    _selectedMoneda = widget.investment?.moneda ?? 'COP';

    // === MES (NORMALIZADO) ===
    final mesFromDb = widget.investment?.mes;
    _selectedMes = _normalizeMonth(mesFromDb) ?? _meses[now.month - 1];

    // === ORIGEN, ACTIVO, ESTADO ===
    _selectedOrigen = widget.investment?.origen ?? _origenes[0];
    _selectedActivo = widget.investment?.activo ?? 'Acciones';
    _selectedEstado = widget.investment?.estado ?? 'Activo';

    // === FECHA DE INVERSIÓN ===
    _selectedFechaInversion = widget.investment?.fechaInversion ?? now;

    // === MONTO ===
    if (widget.investment != null) {
      final monto = widget.investment!.invMensual;
      _montoController.text = UIHelpers.formatDecimal(monto.round());
    } else {
      _montoController.text = '';
    }

    // === DESCRIPCIÓN ===
    _descripcionController.text = widget.investment?.descripcion ?? '';

    // === CAMPOS DE PROYECCIÓN ===
    if (widget.investment?.rendimientoEstimadoEA != null) {
      _rendimientoController.text =
          widget.investment!.rendimientoEstimadoEA!.toString();
    } else {
      _rendimientoController.text = '';
    }

    if (widget.investment?.plazoMeses != null) {
      _plazoMesesController.text =
          widget.investment!.plazoMeses!.toString();
    } else {
      _plazoMesesController.text = '';
    }

    _esAporteRecurrente = widget.investment?.esAporteRecurrente ?? false;
  }

  /// Normaliza cualquier variante del mes a su forma capitalizada estándar
  String? _normalizeMonth(String? mes) {
    if (mes == null || mes.trim().isEmpty) return null;

    final cleaned = mes.trim();
    final lowerCase = cleaned.toLowerCase();

    final index = DateFormat.MMMM('es').dateSymbols.MONTHS.indexWhere(
          (m) => m.toLowerCase() == lowerCase,
        );

    if (index != -1) {
      return _meses[index];
    }

    return null;
  }

  /// Actualiza la conversión de moneda en tiempo real
  Future<void> _updateConversion() async {
    final rawText = _montoController.text;
    final cleanText =
        rawText.replaceAll(RegExp(r'[^\d,]'), '').replaceAll('.', '');
    final monto = double.tryParse(cleanText.replaceAll(',', '.')) ?? 0.0;

    if (monto <= 0 || _selectedMoneda == 'COP') {
      if (mounted) {
        setState(() {
          _tasaConversion = 1.0;
          _montoConvertido = monto;
          _isLoadingConversion = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoadingConversion = true);
    }

    try {
      final currencyService = ref.read(currencyServiceProvider);
      final rate =
          await currencyService.getExchangeRate(_selectedMoneda, 'COP');
      if (mounted) {
        setState(() {
          _tasaConversion = rate;
          _montoConvertido = monto * rate;
        });
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(
            context: context, message: 'No se pudo actualizar la tasa de cambio');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingConversion = false);
      }
    }
  }

  /// Abre el selector de fecha
  Future<void> _selectFechaInversion() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFechaInversion,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedFechaInversion = picked);
    }
  }

  /// Guarda o actualiza la inversión
  Future<void> _guardarInversion() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final rawText = _montoController.text;
    final cleanText =
        rawText.replaceAll(RegExp(r'[^\d,]'), '').replaceAll('.', '');
    final monto = double.tryParse(cleanText.replaceAll(',', '.')) ?? 0.0;

    final rendimientoText =
        _rendimientoController.text.trim().replaceAll(',', '.');
    final rendimiento = double.tryParse(rendimientoText);
    final plazoText = _plazoMesesController.text.trim();
    final plazo = int.tryParse(plazoText);

    final investment = Investment(
      id: widget.investment?.id ?? const Uuid().v4(),
      userId: widget.userId,
      portafolioId: widget.portafolioId,
      fecha: DateTime.now(),
      mes: _selectedMes,
      invMensual: monto,
      moneda: _selectedMoneda,
      descripcion: _descripcionController.text,
      estado: _selectedEstado,
      fechaInversion: _selectedFechaInversion,
      origen: _selectedOrigen,
      activo: _selectedActivo,
      rendimientoEstimadoEA: rendimiento,
      esAporteRecurrente: _esAporteRecurrente,
      plazoMeses: plazo,
    );

    try {
      final service = ref.read(investmentServiceProvider);
      if (widget.investment == null) {
        await service.agregarInvestment(
            widget.userId, widget.portafolioId, investment);
      } else {
        await service.actualizarInvestment(widget.userId, widget.portafolioId,
            widget.investment!.id, investment);
      }

      if (mounted) {
        UIHelpers.showSuccessSnackBar(
            context: context, message: PortafolioStrings.inversionGuardadaExito);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final friendlyError = DbErrorHandler.handle(e);
        UIHelpers.showErrorSnackBar(
            context: context, message: friendlyError);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _montoController.removeListener(_updateConversion);
    _montoController.dispose();
    _descripcionController.dispose();
    _rendimientoController.dispose();
    _plazoMesesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetCatalogAsync = ref.watch(assetCatalogProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: context.isDarkMode ? context.colors.surface : Themes.primary,
        foregroundColor: Colors.white,
        title: Text(
            widget.investment == null ? "Nueva Inversión" : "Editar Inversión"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: CustomFormContainer(
              formKey: _formKey,
              onCancel: _isSaving ? null : () => Navigator.pop(context),
              onSave: _isSaving ? null : _guardarInversion,
              saveButtonText: _isSaving ? 'Guardando...' : 'Guardar',
              cancelButtonText: 'Cancelar',
          children: [
            Text(
              widget.investment == null
                  ? "Registrar Inversión"
                  : "Editar Inversión",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.titleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // === MONTO CON FORMATO ===
            TextFormField(
              controller: _montoController,
              decoration: AppInputStyle.textField(
                label: 'Monto *',
                suffixIcon: const Icon(Icons.monetization_on_outlined),
              ).copyWith(
                prefixText: _selectedMoneda == 'COP' ? '\$ ' : (_selectedMoneda == 'USD' ? 'US\$ ' : '€ '),
                prefixStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.isDarkMode
                        ? context.colors.onSurface
                        : Colors.black87),
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                if (value.isEmpty) {
                  _updateConversion();
                  return;
                }

                final cleanDigits = value.replaceAll(RegExp(r'[^\d]'), '');
                final number = double.tryParse(cleanDigits) ?? 0.0;

                if (number > 0) {
                  final formatted = UIHelpers.formatDecimal(number.round());
                  if (formatted != _montoController.text) {
                    _montoController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                } else {
                  _montoController.text = '';
                }

                _updateConversion();
              },
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'El monto es obligatorio';
                }
                final cleanDigits = val.replaceAll(RegExp(r'[^\d]'), '');
                final parsed = double.tryParse(cleanDigits) ?? 0.0;
                if (parsed <= 0) {
                  return 'El monto debe ser mayor a 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // === MONEDA ===
            DropdownButtonFormField<String>(
              value: _selectedMoneda,
              items: ['COP', 'USD', 'EUR']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) async {
                setState(() => _selectedMoneda = v!);
                await _updateConversion();
              },
              decoration: AppInputStyle.dropdown(label: 'Moneda'),
            ),
            const SizedBox(height: 12),

            // === CONVERSIÓN ===
            if (_isLoadingConversion)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(minHeight: 2),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasa: 1 $_selectedMoneda = ${UIHelpers.formatRate(_tasaConversion)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Convertido: ${UIHelpers.formatCurrency(_montoConvertido)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // === FECHA DE INVERSIÓN ===
            InkWell(
              onTap: _selectFechaInversion,
              child: InputDecorator(
                decoration: AppInputStyle.textField(
                  label: 'Fecha de Inversión',
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedFechaInversion)),
              ),
            ),
            const SizedBox(height: 12),

            // === MES ===
            DropdownButtonFormField<String>(
              value: _selectedMes,
              items: _meses
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedMes = v!),
              decoration: AppInputStyle.dropdown(label: 'Mes'),
            ),
            const SizedBox(height: 12),

            // === ORIGEN ===
            DropdownButtonFormField<String>(
              value: _selectedOrigen,
              items: _origenes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedOrigen = v!),
              decoration: AppInputStyle.dropdown(label: 'Origen'),
            ),
            const SizedBox(height: 12),

            // === ACTIVO ===
            assetCatalogAsync.when(
              data: (catalogList) {
                final items = catalogList.map((e) => e.nombre).toList();
                if (!items.contains(_selectedActivo)) {
                  items.add(_selectedActivo);
                }

                return DropdownButtonFormField<String>(
                  value: _selectedActivo,
                  items: items
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedActivo = v!),
                  decoration: AppInputStyle.dropdown(label: 'Activo'),
                );
              },
              loading: () => DropdownButtonFormField<String>(
                value: _selectedActivo,
                items: [_selectedActivo]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: null,
                decoration: AppInputStyle.dropdown(label: 'Cargando activos...'),
              ),
              error: (err, _) => DropdownButtonFormField<String>(
                value: _selectedActivo,
                items: [_selectedActivo]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: null,
                decoration: AppInputStyle.dropdown(label: 'Error al cargar activos'),
              ),
            ),
            const SizedBox(height: 12),

            // === ESTADO ===
            DropdownButtonFormField<String>(
              value: _selectedEstado,
              items: ['Activo', 'Inactivo']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedEstado = v!),
              decoration: AppInputStyle.dropdown(label: 'Estado'),
            ),
            const SizedBox(height: 12),

            // === DESCRIPCIÓN ===
            TextFormField(
              controller: _descripcionController,
              decoration: AppInputStyle.textField(
                label: 'Descripción',
                suffixIcon: const Icon(Icons.description_outlined),
              ),
              maxLength: 100,
              validator: _validator.validateDescription,
            ),
            const SizedBox(height: 12),

            // === CAMPOS OPCIONALES DE PROYECCIÓN FINANCIERA ===
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: widget.investment?.rendimientoEstimadoEA != null,
                leading: Icon(Icons.trending_up_rounded, color: context.colors.primary),
                title: Text(
                  'Proyección y Rendimiento (Opcional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Configura tasa E.A. y plazo para simulación',
                  style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
                ),
                children: [
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _rendimientoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: AppInputStyle.textField(
                      label: 'Rendimiento Estimado (% E.A.)',
                      suffixIcon: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text('% E.A.', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _plazoMesesController,
                    keyboardType: TextInputType.number,
                    decoration: AppInputStyle.textField(
                      label: 'Plazo Estimado (Meses)',
                      suffixIcon: const Icon(Icons.timer_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('¿Es aporte recurrente?', style: TextStyle(fontSize: 14)),
                    subtitle: const Text(
                      'Indica si planeas aportar este monto periódicamente',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _esAporteRecurrente,
                    onChanged: (val) => setState(() => _esAporteRecurrente = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}

