import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../../core/data/utils/ui_helpers.dart';
// import 'package:finances/core/errors/handlers/db_error_handler.dart'; // Ideal para la fase 1

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

class EgresoForm extends ConsumerStatefulWidget {
  final Egreso? egreso;

  const EgresoForm({super.key, this.egreso});

  @override
  ConsumerState<EgresoForm> createState() => _EgresoFormState();
}

class _EgresoFormState extends ConsumerState<EgresoForm> {
  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _valorController = TextEditingController();
  final _descripcionController = TextEditingController();

  String? _quincena = 'Primera Quincena';
  DateTime fechaPago = DateTime.now();
  String? _categoria = 'Otros';
  String? _estado = 'Pendiente';
  DateTime _fechaActual = DateTime.now();
  bool _isLoading = false;

  final List<String> _quincenas = ['Primera Quincena', 'Segunda Quincena', 'Diario', 'Mensual'];
  final List<String> _categorias = ['Alimentación', 'Transporte', 'Vivienda', 'Entretenimiento', 'Ahorro', 'Vacaciones', 'Transferencia', 'Otros'];
  final List<String> _estados = ['Pendiente', 'Cancelado'];

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
    if (widget.egreso != null) {
      _conceptoController.text = widget.egreso!.concepto;
      _valorController.text = UIHelpers.formatCurrency(widget.egreso!.valor.toDouble());
      _descripcionController.text = widget.egreso!.descripcion;

      _quincena = _quincenaToDisplay[widget.egreso!.quincena] ?? widget.egreso!.quincena;
      if (_quincena != null && !_quincenas.contains(_quincena)) _quincena = _quincenas.first;

      fechaPago = widget.egreso!.fechaPago;
      _fechaActual = widget.egreso!.fecha;

      _categoria = widget.egreso!.categoria;
      if (_categoria != null && !_categorias.contains(_categoria)) _categoria = _categorias.last;

      _estado = widget.egreso!.estado;
      if (_estado != null && !_estados.contains(_estado)) _estado = _estados.first;
    }
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _valorController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardarEgreso() async {
    if (!_formKey.currentState!.validate()) return;
    
    String valorLimpo = _valorController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (valorLimpo.isEmpty) {
      UIHelpers.showErrorSnackBar(context: context, message: 'El valor no puede estar vacío');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final egreso = Egreso(
        id: widget.egreso?.id ?? _generarIdAleatorio(),
        concepto: _conceptoController.text,
        valor: int.parse(valorLimpo),
        quincena: _displayToQuincena[_quincena!] ?? _quincena!,
        fechaPago: fechaPago,
        fecha: _fechaActual,
        categoria: _categoria ?? 'Otros',
        estado: _estado ?? 'Pendiente',
        descripcion: _descripcionController.text,
      );

      final service = ref.read(egresoServiceProvider);
      if (widget.egreso == null) {
        await service.addEgreso(user.uid, egreso);
      } else {
        await service.actualizarEgreso(user.uid, egreso);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.egreso == null ? 'Gasto registrado con éxito' : 'Gasto actualizado con éxito'),
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
    final isEditing = widget.egreso != null;
    
    return Scaffold(
      backgroundColor: context.scaffoldBgColor,
      appBar: AppBarFinances(
        title: isEditing ? 'Editar Gasto' : 'Nuevo Gasto',
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
                            Text('Monto del gasto', style: TextStyle(color: context.isDarkMode ? Colors.white70 : Colors.black54, fontSize: 14)),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 250,
                              child: TextFormField(
                                controller: _valorController,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: context.isDarkMode ? context.colors.error : Themes.red),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '\$0',
                                  hintStyle: TextStyle(color: context.isDarkMode ? Colors.white70 : Colors.grey),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [CurrencyFormatterFromHelper()],
                                validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // SECCIÓN DETALLES
                      Text('Detalles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.isDarkMode ? context.colors.onSurface : Colors.black87)),
                      const SizedBox(height: 16),
                      buildTextField(_conceptoController, 'Concepto (Ej. Mercado, Cine)', Icons.edit_note),
                      const SizedBox(height: 16),
                      
                      // SECCIÓN CATEGORÍA (CHIPS)
                      Text('Categoría', style: TextStyle(fontSize: 14, color: context.isDarkMode ? context.colors.onSurfaceVariant : Colors.black87)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categorias.map((cat) {
                          final isSelected = _categoria == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: context.isDarkMode ? context.colors.primary.withValues(alpha: 0.3) : Themes.primary.withValues(alpha: 0.2),
                            backgroundColor: context.isDarkMode ? context.colors.surfaceContainerHigh : Colors.grey.shade100,
                            side: BorderSide(color: context.isDarkMode ? Colors.white12 : Colors.transparent),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? (context.isDarkMode ? context.colors.primary : Themes.primary)
                                  : (context.isDarkMode ? context.colors.onSurface : Colors.black87),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _categoria = cat);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // FECHA Y QUINCENA
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: fechaPago,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: context.colors.primary,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) setState(() => fechaPago = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: context.cardBgColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: context.isDarkMode ? Colors.white12 : Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Fecha de pago', style: TextStyle(color: context.isDarkMode ? context.colors.onSurfaceVariant : Colors.grey, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 16, color: context.colors.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            DateFormat('dd MMM yyyy').format(fechaPago), 
                                            style: TextStyle(fontWeight: FontWeight.bold, color: context.isDarkMode ? context.colors.onSurface : Colors.black87),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _quincena,
                              dropdownColor: context.dialogBgColor,
                              items: _quincenas.map((item) => DropdownMenuItem(value: item, child: Text(item, style: TextStyle(fontSize: 14, color: context.isDarkMode ? context.colors.onSurface : Colors.black87)))).toList(),
                              onChanged: (val) => setState(() => _quincena = val),
                              decoration: InputDecoration(
                                labelText: 'Periodo',
                                filled: true,
                                fillColor: context.cardBgColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.isDarkMode ? Colors.white12 : Colors.grey[300]!)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.isDarkMode ? Colors.white12 : Colors.grey[300]!)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ESTADO
                      DropdownButtonFormField<String>(
                        value: _estado,
                        dropdownColor: context.dialogBgColor,
                        items: _estados.map((item) => DropdownMenuItem(value: item, child: Text(item, style: TextStyle(color: context.isDarkMode ? context.colors.onSurface : Colors.black87)))).toList(),
                        onChanged: (val) => setState(() => _estado = val),
                        decoration: InputDecoration(
                          labelText: 'Estado del pago',
                          filled: true,
                          fillColor: context.cardBgColor,
                          prefixIcon: Icon(_estado == 'Cancelado' ? Icons.check_circle : Icons.pending_actions, color: _estado == 'Cancelado' ? Themes.green : Colors.orange),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.isDarkMode ? Colors.white12 : Colors.grey[300]!)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.isDarkMode ? Colors.white12 : Colors.grey[300]!)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // DESCRIPCIÓN
                      buildTextField(_descripcionController, 'Nota adicional (Opcional)', Icons.description, isMultiline: true),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            
            // BOTÓN GUARDAR (Sticky al fondo)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: context.cardBgColor,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _guardarEgreso,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isEditing ? 'Actualizar Gasto' : 'Registrar Gasto',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String hint, IconData icon, {bool isMultiline = false}) {
    return TextFormField(
      controller: controller,
      maxLines: isMultiline ? 3 : 1,
      minLines: isMultiline ? 3 : 1,
      style: TextStyle(color: context.isDarkMode ? context.colors.onSurface : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.isDarkMode ? Colors.white38 : Colors.grey),
        filled: true,
        fillColor: context.cardBgColor,
        prefixIcon: isMultiline ? null : Icon(icon, color: context.isDarkMode ? Colors.white54 : Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.isDarkMode ? Colors.white12 : Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.isDarkMode ? Colors.white12 : Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.colors.primary, width: 2)),
      ),
      validator: isMultiline ? null : (value) => value == null || value.isEmpty ? 'Requerido' : null,
    );
  }
}
