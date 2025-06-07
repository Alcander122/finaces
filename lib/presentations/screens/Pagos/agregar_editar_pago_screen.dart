// agregar_editar_pago_screen.dart
import 'package:finances/core/data/models/pago_model.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/payment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AgregarEditarPagoScreen extends ConsumerStatefulWidget {
  const AgregarEditarPagoScreen({super.key});

  @override
  ConsumerState<AgregarEditarPagoScreen> createState() =>
      _AgregarEditarPagoScreenState();
}

class _AgregarEditarPagoScreenState
    extends ConsumerState<AgregarEditarPagoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _montoController = TextEditingController();
  late DateTime _fechaVencimiento;
  bool _esProgramado = false;
  bool _datosInicializados = false;

  @override
  void initState() {
    super.initState();
    _fechaVencimiento = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_datosInicializados) {
      final args = ModalRoute.of(context)?.settings.arguments as Pago?;
      if (args != null) {
        _descripcionController.text = args.descripcion;
        _montoController.text = args.monto.toString();
        _fechaVencimiento = args.fechaVencimiento;
        _esProgramado = args.estaProgramado;
      }
      _datosInicializados = true;
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _guardarPago(BuildContext context, WidgetRef ref) async {
    if (_formKey.currentState!.validate()) {
      try {
        final authState = ref.read(authProvider);
        if (authState.user == null) {
          throw Exception("Debe estar autenticado");
        }
        final provider = ref.read(paymentProvider(authState.user!.uid).notifier);
        final nuevoPago = Pago(
          id: '',
          descripcion: _descripcionController.text.trim(),
          monto: double.parse(_montoController.text),
          fechaVencimiento: _fechaVencimiento,
          estaProgramado: _esProgramado,
        );
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Pago) {
          final pagoExistente = args;
          await provider.editarPago(
            pagoExistente.copyWith(
              descripcion: nuevoPago.descripcion,
              monto: nuevoPago.monto,
              fechaVencimiento: nuevoPago.fechaVencimiento,
              estaProgramado: nuevoPago.estaProgramado,
            ),
          );
        } else {
          await provider.agregarPago(nuevoPago);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error guardando pago: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ModalRoute.of(context)?.settings.arguments is Pago
            ? "Editar Pago"
            : "Nuevo Pago"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: "Descripción",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? "Campo requerido" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Monto",
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Campo requerido";
                  if (double.tryParse(value!) == null) return "Valor inválido";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  "Fecha de vencimiento: ${_fechaVencimiento.toLocal().toString().split(' ')[0]}",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _fechaVencimiento,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _fechaVencimiento = date);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("Pago programado/recurrente"),
                value: _esProgramado,
                onChanged: (value) => setState(() => _esProgramado = value),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _guardarPago(context, ref),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("GUARDAR", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}