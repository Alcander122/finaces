import 'package:finances/core/data/models/investment_model.dart';
import 'package:finances/core/data/services/currency_service.dart';
import 'package:finances/core/data/services/investment_service.dart';
import 'package:finances/core/data/utils/Portafolio_validator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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
  InvestmentFormScreenState createState() => InvestmentFormScreenState();
}

class InvestmentFormScreenState extends State<InvestmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final CurrencyService currencyService = CurrencyService();
  final FormValidator validator = FormValidator();

  late String _selectedMoneda;
  late String _selectedMes;
  late String _selectedOrigen;
  late String _selectedActivo;
  late String _selectedEstado;
  double _tasaConversion = 1.0;
  double _montoConvertido = 0.0;
  late DateTime _selectedFechaInversion;

  final List<String> _meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];

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

    _selectedMoneda = 'COP';
    _selectedMes = _meses[DateTime.now().month - 1];
    _selectedOrigen = _origenes[0];
    _selectedActivo = _activos[0];
    _selectedEstado = 'Activo';
    _selectedFechaInversion = DateTime.now();

    if (widget.investment != null) {
      _montoController.text = widget.investment!.invMensual.toString();
      _descripcionController.text = widget.investment!.descripcion;
      _selectedMoneda = widget.investment!.moneda;
      _selectedMes = widget.investment!.mes;
      _selectedOrigen = widget.investment!.origen;
      _selectedActivo = widget.investment!.activo;
      _selectedEstado = widget.investment!.estado;
      _selectedFechaInversion = widget.investment!.fechaInversion;
    }

    _montoController.addListener(_updateConversion);
    _updateConversion();
  }

  Future<void> _updateConversion() async {
    final monto = double.tryParse(_montoController.text) ?? 0;

    // Tasa de conversión fija para COP a USD (1 COP = 0.0003 USD)
    const tasaCOPtoUSD = 0.0003;
    const tasaUSDtoCOP = 1 / tasaCOPtoUSD;

    setState(() {
      if (_selectedMoneda == 'COP') {
        // Convertir de COP a USD
        _tasaConversion = tasaCOPtoUSD;
        _montoConvertido = monto * _tasaConversion;
      } else {
        // Convertir de USD a COP
        _tasaConversion = tasaUSDtoCOP;
        _montoConvertido = monto * _tasaConversion;
      }
    });
  }

  Future<void> _selectFechaInversion(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFechaInversion,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedFechaInversion) {
      setState(() {
        _selectedFechaInversion = picked;
      });
    }
  }

  Future<void> _guardarInversion() async {
    if (_formKey.currentState!.validate()) {
      final investment = Investment(
        id: widget.investment?.id ?? const Uuid().v4(),
        userId: widget.userId,
        portafolioId: widget.portafolioId,
        fecha: DateTime.now(),
        mes: _selectedMes,
        invMensual: double.parse(_montoController.text),
        moneda: _selectedMoneda,
        descripcion: _descripcionController.text,
        estado: _selectedEstado,
        fechaInversion: _selectedFechaInversion,
        origen: _selectedOrigen,
        activo: _selectedActivo,
      );

      if (widget.investment == null) {
        await InvestmentService()
            .agregarInvestment(widget.userId, widget.portafolioId, investment);
      } else {
        await InvestmentService().actualizarInvestment(widget.userId,
            widget.portafolioId, widget.investment!.id, investment);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inversión guardada correctamente')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.investment == null ? "Nueva Inversión" : "Editar Inversión"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Campo de Monto
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese un monto';
                  final amount = double.tryParse(value);
                  if (amount == null) return 'Monto inválido';
                  if (amount <= 0) return 'Monto debe ser positivo';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Selector de Moneda
              DropdownButtonFormField<String>(
                value: _selectedMoneda,
                items: ['COP', 'USD', 'EUR']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) async {
                  setState(() => _selectedMoneda = value!);
                  await _updateConversion();
                },
                decoration: const InputDecoration(labelText: 'Moneda'),
              ),
              const SizedBox(height: 10),

              // Tasa de conversión
              Text(
                'Tasa de conversión: 1 $_selectedMoneda = ${_tasaConversion.toStringAsFixed(4)} ${_selectedMoneda == 'COP' ? 'USD' : 'COP'}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),

              // Monto convertido (con decimales)
              Text(
                'Monto convertido: ${_montoConvertido.toStringAsFixed(2)} ${_selectedMoneda == 'COP' ? 'USD' : 'COP'}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),

              // Selector de Fecha de Inversión
              InkWell(
                onTap: () => _selectFechaInversion(context),
                child: InputDecorator(
                  decoration:
                      const InputDecoration(labelText: 'Fecha de Inversión'),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedFechaInversion),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Selector de Mes
              DropdownButtonFormField<String>(
                value: _selectedMes,
                items: _meses
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedMes = value!),
                decoration: const InputDecoration(labelText: 'Mes'),
              ),
              const SizedBox(height: 10),

              // Selector de Origen
              DropdownButtonFormField<String>(
                value: _selectedOrigen,
                items: _origenes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedOrigen = value!),
                decoration: const InputDecoration(labelText: 'Origen'),
              ),
              const SizedBox(height: 10),

              // Selector de Activo
              DropdownButtonFormField<String>(
                value: _selectedActivo,
                items: _activos
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedActivo = value!),
                decoration: const InputDecoration(labelText: 'Activo'),
              ),
              const SizedBox(height: 10),

              // Selector de Estado
              DropdownButtonFormField<String>(
                value: _selectedEstado,
                items: ['Activo', 'Inactivo']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedEstado = value!),
                decoration: const InputDecoration(labelText: 'Estado'),
              ),
              const SizedBox(height: 10),

              // Campo de Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLength: 100,
              ),
              const SizedBox(height: 20),

              // Botón de Guardar
              ElevatedButton(
                onPressed: _guardarInversion,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
