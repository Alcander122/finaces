import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../../core/data/utils/ui_helpers.dart';

class CurrencyFormatterFromHelper extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final number = double.tryParse(digits) ?? 0;
    final formatted = UIHelpers.formatCurrency(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class IngresoForm extends ConsumerStatefulWidget {
  final Ingreso? ingreso;

  const IngresoForm({super.key, this.ingreso});

  @override
  ConsumerState<IngresoForm> createState() => _IngresoFormState();
}

class _IngresoFormState extends ConsumerState<IngresoForm> {
  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _valorController = TextEditingController();

  String? _quincena = 'Primera Quincena';
  DateTime fechaIngreso = DateTime.now();
  String? _categoria = 'Salario';
  DateTime _fechaActual = DateTime.now();
  bool _isLoading = false;

  final List<String> _quincenas = ['Primera Quincena', 'Segunda Quincena', 'Diario', 'Mensual'];
  final List<String> _categorias = [
    'Salario',
    'Bonificación',
    'Reembolso',
    'Intereses',
    'Devolución',
    'Transferencia',
    'Otros'
  ];

  final Map<String, String> _quincenaToDisplay = {
    'Primera': 'Primera Quincena',
    'Segunda': 'Segunda Quincena',
    'Diario': 'Diario',
    'Mensual': 'Mensual',
  };

  final Map<String, String> _displayToQuincena = {
    'Primera Quincena': 'Primera',
    'Segunda Quincena': 'Segunda',
    'Diario': 'Diario',
    'Mensual': 'Mensual',
  };

  @override
  void initState() {
    super.initState();
    if (widget.ingreso != null) {
      _conceptoController.text = widget.ingreso!.concepto;
      _valorController.text = UIHelpers.formatCurrency(widget.ingreso!.valor.toDouble());

      _quincena = _quincenaToDisplay[widget.ingreso!.quincena] ?? widget.ingreso!.quincena;
      if (_quincena != null && !_quincenas.contains(_quincena)) _quincena = _quincenas.first;

      fechaIngreso = widget.ingreso!.fechaIngreso;
      _fechaActual = widget.ingreso!.fecha;

      _categoria = widget.ingreso!.categoria;
      if (_categoria != null && !_categorias.contains(_categoria)) _categoria = _categorias.last;
    }
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _guardarIngreso() async {
    if (!_formKey.currentState!.validate()) return;
    
    String valorLimpo = _valorController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (valorLimpo.isEmpty) {
      UIHelpers.showErrorSnackBar(context: context, message: 'El valor no puede estar vacío');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).user;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final String quincenaInterna = _displayToQuincena[_quincena!] ?? _quincena!;
      int valorNumerico = int.parse(valorLimpo);
      
      final ingreso = Ingreso(
        id: widget.ingreso?.id ?? _generarIdAleatorio(),
        quincena: quincenaInterna,
        fecha: _fechaActual,
        fechaIngreso: fechaIngreso,
        categoria: _categoria!,
        concepto: _conceptoController.text,
        valor: valorNumerico,
      );

      final service = ref.read(ingresosServiceProvider);
      if (widget.ingreso == null) {
        await service.guardarIngreso(user.uid, ingreso);
      } else {
        await service.actualizarIngreso(user.uid, ingreso.id, ingreso);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.ingreso == null ? 'Ingreso registrado con éxito' : 'Ingreso actualizado con éxito'),
            backgroundColor: Themes.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(context: context, message: 'Ocurrió un error al guardar: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _generarIdAleatorio() {
    const caracteres = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(20, (index) => caracteres[random.nextInt(caracteres.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.ingreso != null;
    
    return Scaffold(
      backgroundColor: Themes.light,
      appBar: AppBarFinances(
        title: isEditing ? 'Editar Ingreso' : 'Nuevo Ingreso',
        showProfileIcon: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECCIÓN VALOR
                      Center(
                        child: Column(
                          children: [
                            const Text('Monto del ingreso', style: TextStyle(color: Colors.black54, fontSize: 14)),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 250,
                              child: TextFormField(
                                controller: _valorController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Themes.primary),
                                inputFormatters: [CurrencyFormatterFromHelper()],
                                decoration: const InputDecoration(
                                  prefixText: '\$ ',
                                  prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Themes.primary),
                                  border: InputBorder.none,
                                  hintText: '0',
                                  hintStyle: TextStyle(fontSize: 32, color: Colors.black26),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty || value == '0') {
                                    return 'Ingrese un monto válido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // TARJETA DE DETALLES
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // PERIODICIDAD
                            _buildDropdownField(
                              icon: Icons.update,
                              label: 'Periodo',
                              value: _quincena,
                              items: _quincenas,
                              onChanged: (val) => setState(() => _quincena = val),
                            ),
                            const Divider(height: 24, color: Colors.black12),

                            // FECHA DE INGRESO
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: fechaIngreso,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Themes.primary,
                                          onPrimary: Colors.white,
                                          onSurface: Colors.black87,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (date != null) {
                                  setState(() => fechaIngreso = date);
                                }
                              },
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Themes.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.calendar_today, color: Themes.primary, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Fecha de ingreso', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                        const SizedBox(height: 4),
                                        Text(DateFormat('dd MMM yyyy').format(fechaIngreso), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black26),
                                ],
                              ),
                            ),
                            const Divider(height: 24, color: Colors.black12),

                            // CATEGORÍA
                            _buildDropdownField(
                              icon: Icons.category,
                              label: 'Categoría',
                              value: _categoria,
                              items: _categorias,
                              onChanged: (val) => setState(() => _categoria = val),
                            ),
                            const Divider(height: 24, color: Colors.black12),

                            // CONCEPTO
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Themes.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.description, color: Themes.primary, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _conceptoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Concepto (Opcional)',
                                      labelStyle: TextStyle(fontSize: 14, color: Colors.black54),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // BOTÓN DE GUARDAR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardarIngreso,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Themes.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          isEditing ? 'Guardar Cambios' : 'Registrar Ingreso',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required IconData icon,
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Themes.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Themes.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isDense: true,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black26),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                  onChanged: onChanged,
                  items: items.map((String item) {
                    return DropdownMenuItem<String>(value: item, child: Text(item));
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
