// investment_form_screen.dart
import 'package:finances/core/data/models/investment_model.dart';
import 'package:finances/core/data/services/currency_service.dart';
import 'package:finances/core/data/services/investment_service.dart';
import 'package:finances/core/data/utils/form_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← NECESARIO
import 'package:intl/intl.dart';
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

  late String _selectedMoneda;
  late String _selectedMes;
  late String _selectedOrigen;
  late String _selectedActivo;
  late String _selectedEstado;
  late DateTime _selectedFechaInversion;

  double _tasaConversion = 1.0;
  double _montoConvertido = 0.0;
  bool _isLoadingConversion = false;

  final List<String> _meses = DateFormat.MMMM('es').dateSymbols.MONTHS;
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
    _initializeFields();
    _montoController.addListener(_updateConversion);
    _updateConversion();
  }

  void _initializeFields() {
    final now = DateTime.now();
    _selectedMoneda = widget.investment?.moneda ?? 'COP';
    _selectedMes = widget.investment?.mes ?? _meses[now.month - 1];
    _selectedOrigen = widget.investment?.origen ?? _origenes[0];
    _selectedActivo = widget.investment?.activo ?? _activos[0];
    _selectedEstado = widget.investment?.estado ?? 'Activo';
    _selectedFechaInversion = widget.investment?.fechaInversion ?? now;

    // ← MONTO CON 2 DECIMALES SIEMPRE
    final monto = widget.investment?.invMensual ?? 0.0;
    _montoController.text = UIHelpers.formatCurrency(monto);

    _descripcionController.text = widget.investment?.descripcion ?? '';
  }

  Future<void> _updateConversion() async {
    // ← LIMPIAR FORMATO PARA OBTENER NÚMERO REAL
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
            context: context, message: 'Error en conversión');
      }
    } finally {
      if (mounted) setState(() => _isLoadingConversion = false);
    }
  }

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

  Future<void> _guardarInversion() async {
    if (!_formKey.currentState!.validate()) return;

    // ← OBTENER NÚMERO LIMPIO
    final rawText = _montoController.text;
    final cleanText =
        rawText.replaceAll(RegExp(r'[^\d,]'), '').replaceAll('.', '');
    final monto = double.tryParse(cleanText.replaceAll(',', '.')) ?? 0.0;

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
              // === MONTO CON FORMATO $ 2.000,00 ===
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(labelText: 'Monto *'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                onChanged: (value) {
                  final clean = value
                      .replaceAll(RegExp(r'[^\d,]'), '')
                      .replaceAll('.', '');
                  final parts = clean.split(',');
                  final integer = parts[0];
                  final decimal = parts.length > 1
                      ? parts[1].substring(0, parts[1].length.clamp(0, 2))
                      : '00';
                  final numStr = '$integer.$decimal';
                  final num = double.tryParse(numStr);
                  if (num != null) {
                    final formatted = UIHelpers.formatCurrency(num);
                    _montoController.value = TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                  _updateConversion();
                },
                validator: _validator.validateAmount,
              ),
              const SizedBox(height: 12),

              // === MONEDA ===
              DropdownButtonFormField<String>(
                initialValue: _selectedMoneda,
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

              // === FECHA ===
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

              // === MES ===
              DropdownButtonFormField<String>(
                initialValue: _selectedMes,
                items: _meses
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMes = v!),
                decoration: const InputDecoration(labelText: 'Mes'),
              ),
              const SizedBox(height: 12),

              // === ORIGEN ===
              DropdownButtonFormField<String>(
                initialValue: _selectedOrigen,
                items: _origenes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedOrigen = v!),
                decoration: const InputDecoration(labelText: 'Origen'),
              ),
              const SizedBox(height: 12),

              // === ACTIVO ===
              DropdownButtonFormField<String>(
                initialValue: _selectedActivo,
                items: _activos
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedActivo = v!),
                decoration: const InputDecoration(labelText: 'Activo'),
              ),
              const SizedBox(height: 12),

              // === ESTADO ===
              DropdownButtonFormField<String>(
                initialValue: _selectedEstado,
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

              // === GUARDAR ===
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
