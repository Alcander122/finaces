import 'package:finances/core/data/models/investment_model.dart';
import 'package:finances/core/data/services/currency_service.dart';
import 'package:finances/core/data/services/investment_service.dart';
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
  _InvestmentFormScreenState createState() => _InvestmentFormScreenState();
}

class _InvestmentFormScreenState extends State<InvestmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final CurrencyService _currencyService = CurrencyService();

  late String _selectedMoneda;
  late String _selectedMes;
  late String _selectedOrigen;
  late String _selectedActivo;
  late String _selectedEstado;
  double _tasaConversion = 1.0;
  double _montoConvertido = 0.0;

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
    _selectedOrigen = _origenes[0]; // Default
    _selectedActivo = _activos[0]; // Default
    _selectedEstado = 'Activo';

    if (widget.investment != null) {
      _montoController.text = widget.investment!.invMensual.toString();
      _descripcionController.text = widget.investment!.descripcion;
      _selectedMoneda = widget.investment!.moneda;
      _selectedMes = widget.investment!.mes;
      _selectedOrigen = widget.investment!.origen;
      _selectedActivo = widget.investment!.activo;
      _selectedEstado = widget.investment!.estado;
    }

    _montoController.addListener(_updateConversion);
  }

  void _updateConversion() {
    final monto = double.tryParse(_montoController.text) ?? 0;
    setState(() {
      _montoConvertido = _selectedMoneda == 'COP'
          ? monto * _tasaConversion
          : monto / _tasaConversion;
    });
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
        fechaInversion: DateTime.now(),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese un monto' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedMoneda,
                items: ['COP', 'USD', 'EUR']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedMoneda = value!),
                decoration: const InputDecoration(labelText: 'Moneda'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedMes,
                items: _meses
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedMes = value!),
                decoration: const InputDecoration(labelText: 'Mes'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedOrigen,
                items: _origenes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedOrigen = value!),
                decoration: const InputDecoration(labelText: 'Origen'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedActivo,
                items: _activos
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedActivo = value!),
                decoration: const InputDecoration(labelText: 'Activo'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedEstado,
                items: ['Activo', 'Inactivo']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedEstado = value!),
                decoration: const InputDecoration(labelText: 'Estado'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLength: 100,
              ),
              const SizedBox(height: 20),
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
