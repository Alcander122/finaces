import 'package:finances/core/data/models/investment_model.dart';
import 'package:finances/core/data/services/currency_service.dart';
import 'package:finances/core/data/services/investment_service.dart';
import 'package:finances/core/data/utils/form_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';

class InvestmentFormScreen extends StatefulWidget {
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
  State<InvestmentFormScreen> createState() => _InvestmentFormScreenState();
}

class _InvestmentFormScreenState extends State<InvestmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _currencyService = CurrencyService();
  final _validator = FormValidator();

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

  // === LISTAS DE OPCIONES ===
  // MESES: Capitalizados correctamente (Enero, Febrero, ...)
  late final List<String> _meses;

  final List<String> _origenes = [
    'Ahorros',
    'Salario',
    'Rendimientos',
    'Otros'
  ];

  final List<String> _activos = [
    'ETF SP&500',
    'Acciones',
    'Criptomonedas',
    'Bonos'
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
        // Validar después de cargar para limpiar errores visuales
        _formKey.currentState?.validate();
      }
    });
    // 2. Inicializar todos los campos
    _initializeFields();

    // 3. Escuchar cambios en el monto para conversión
    _montoController.addListener(_updateConversion);
    _updateConversion(); // Conversión inicial
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
    _selectedActivo = widget.investment?.activo ?? _activos[0];
    _selectedEstado = widget.investment?.estado ?? 'Activo';

    // === FECHA DE INVERSIÓN ===
    _selectedFechaInversion = widget.investment?.fechaInversion ?? now;

    // === MONTO (SIEMPRE 2 DECIMALES) ===
    final monto = widget.investment?.invMensual ?? 0.0;
    _montoController.text = UIHelpers.formatCurrency(monto);

    // === DESCRIPCIÓN ===
    _descripcionController.text = widget.investment?.descripcion ?? '';
  }

  /// Normaliza cualquier variante del mes a su forma capitalizada estándar
  /// Ej: "octubre", "OCTUBRE", "Octubre" → "Octubre"
  String? _normalizeMonth(String? mes) {
    if (mes == null || mes.trim().isEmpty) return null;

    final cleaned = mes.trim();
    final lowerCase = cleaned.toLowerCase();

    // Buscar en la lista original en minúsculas
    final index = DateFormat.MMMM('es').dateSymbols.MONTHS.indexWhere(
          (m) => m.toLowerCase() == lowerCase,
        );

    if (index != -1) {
      return _meses[index]; // Devuelve "Octubre", "Enero", etc.
    }

    return null; // No encontrado
  }

  /// Actualiza la conversión de moneda en tiempo real
  Future<void> _updateConversion() async {
    // Limpiar formato: "$ 1.234,56" → "1234.56"
    final rawText = _montoController.text;
    final cleanText =
        rawText.replaceAll(RegExp(r'[^\d,]'), '').replaceAll('.', '');
    final monto = double.tryParse(cleanText.replaceAll(',', '.')) ?? 0.0;

    if (monto <= 0 || _selectedMoneda == 'COP') {
      setState(() {
        _tasaConversion = 1.0;
        _montoConvertido = monto;
        _isLoadingConversion = false;
      });
      return;
    }

    setState(() => _isLoadingConversion = true);

    try {
      final rate =
          await _currencyService.getExchangeRate(_selectedMoneda, 'COP');
      setState(() {
        _tasaConversion = rate;
        _montoConvertido = monto * rate;
      });
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(
            context: context, message: 'Error en conversión de moneda');
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
    if (!_formKey.currentState!.validate()) return;

    // Limpiar monto
    final rawText = _montoController.text;
    final cleanText =
        rawText.replaceAll(RegExp(r'[^\d,]'), '').replaceAll('.', '');
    final monto = double.tryParse(cleanText.replaceAll(',', '.')) ?? 0.0;

    final investment = Investment(
      id: widget.investment?.id ?? const Uuid().v4(),
      userId: widget.userId,
      portafolioId: widget.portafolioId,
      fecha: DateTime.now(),
      mes: _selectedMes, // ← Siempre capitalizado y válido
      invMensual: monto,
      moneda: _selectedMoneda,
      descripcion: _descripcionController.text,
      estado: _selectedEstado,
      fechaInversion: _selectedFechaInversion,
      origen: _selectedOrigen,
      activo: _selectedActivo,
    );

    try {
      final service = InvestmentService();
      if (widget.investment == null) {
        await service.agregarInvestment(
            widget.userId, widget.portafolioId, investment);
      } else {
        await service.actualizarInvestment(widget.userId, widget.portafolioId,
            widget.investment!.id, investment);
      }

      if (mounted) {
        UIHelpers.showSuccessSnackBar(
            context: context, message: 'Inversión guardada');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(
            context: context, message: 'Error al guardar');
      }
    }
  }

  @override
  void dispose() {
    _montoController.removeListener(_updateConversion);
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.investment == null ? "Nueva Inversión" : "Editar Inversión"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // === MONTO CON FORMATO ===
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(labelText: 'Monto *'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                onChanged: (value) {
                  // Evitar bucle infinito
                  if (value == _montoController.text) return;

                  final clean = value
                      .replaceAll(RegExp(r'[^\d,]'), '')
                      .replaceAll('.', '');

                  final parts = clean.split(',');
                  final integer = parts[0];
                  final decimal = parts.length > 1
                      ? parts[1]
                          .substring(0, min(2, parts[1].length))
                          .padRight(2, '0')
                      : '00';

                  final numberStr = '$integer.$decimal';
                  final number = double.tryParse(numberStr);

                  if (number != null && number > 0) {
                    final formatted = UIHelpers.formatCurrency(number);
                    if (formatted != _montoController.text) {
                      _montoController.value = TextEditingValue(
                        text: formatted,
                        selection:
                            TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  }

                  _updateConversion();
                },
                validator: _validator.validateAmount,
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
                decoration: const InputDecoration(labelText: 'Moneda'),
              ),
              const SizedBox(height: 12),

              // === CONVERSIÓN ===
              if (_isLoadingConversion)
                const LinearProgressIndicator(minHeight: 2)
              else ...[
                Text(
                  'Tasa: 1 $_selectedMoneda = ${UIHelpers.formatRate(_tasaConversion)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
              const SizedBox(height: 12),

              // === FECHA DE INVERSIÓN ===
              InkWell(
                onTap: _selectFechaInversion,
                child: InputDecorator(
                  decoration:
                      const InputDecoration(labelText: 'Fecha de Inversión'),
                  child: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedFechaInversion)),
                ),
              ),
              const SizedBox(height: 12),

              // === MES (SOLUCIONADO) ===
              DropdownButtonFormField<String>(
                value: _selectedMes,
                items: _meses
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMes = v!),
                decoration: const InputDecoration(labelText: 'Mes'),
              ),
              const SizedBox(height: 12),

              // === ORIGEN ===
              DropdownButtonFormField<String>(
                value: _selectedOrigen,
                items: _origenes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedOrigen = v!),
                decoration: const InputDecoration(labelText: 'Origen'),
              ),
              const SizedBox(height: 12),

              // === ACTIVO ===
              DropdownButtonFormField<String>(
                value: _selectedActivo,
                items: _activos
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedActivo = v!),
                decoration: const InputDecoration(labelText: 'Activo'),
              ),
              const SizedBox(height: 12),

              // === ESTADO ===
              DropdownButtonFormField<String>(
                value: _selectedEstado,
                items: ['Activo', 'Inactivo']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedEstado = v!),
                decoration: const InputDecoration(labelText: 'Estado'),
              ),
              const SizedBox(height: 12),

              // === DESCRIPCIÓN ===
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLength: 100,
                validator: _validator.validateDescription,
              ),
              const SizedBox(height: 24),

              // === BOTÓN GUARDAR ===
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardarInversion,
                  child: const Text('Guardar Inversión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
