import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/scheduled_payments_provider.dart';
import '../../data/scheduled_payment_model.dart';

class CreatePaymentScreen extends ConsumerStatefulWidget {
  final ScheduledPayment? paymentToEdit;

  const CreatePaymentScreen({super.key, this.paymentToEdit});

  @override
  ConsumerState<CreatePaymentScreen> createState() => _CreatePaymentScreenState();
}

class _CreatePaymentScreenState extends ConsumerState<CreatePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  
  late DateTime _selectedDate;
  late String _selectedFrequency;
  late Set<int> _selectedReminders;

  bool _isLoading = false;

  bool get _isEditMode => widget.paymentToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _titleController.text = widget.paymentToEdit!.title;
      _amountController.text = widget.paymentToEdit!.amount.toString();
      _selectedDate = widget.paymentToEdit!.dueDate;
      _selectedFrequency = widget.paymentToEdit!.frequency;
      _selectedReminders = widget.paymentToEdit!.reminders.toSet();
    } else {
      _selectedDate = DateTime.now().add(const Duration(days: 1));
      _selectedFrequency = 'none';
      _selectedReminders = {1};
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(), // Bloquea fechas en el pasado
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validación de fecha en el pasado
    if (_selectedDate.isBefore(DateTime.now()) && !_isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha de vencimiento no puede estar en el pasado'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditMode) {
        final updatedPayment = ScheduledPayment(
          id: widget.paymentToEdit!.id,
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          dueDate: _selectedDate,
          frequency: _selectedFrequency,
          reminders: _selectedReminders.toList(),
          baseNotificationId: widget.paymentToEdit!.baseNotificationId,
          isPaid: widget.paymentToEdit!.isPaid,
        );
        await ref.read(paymentControllerProvider).updateScheduledPayment(updatedPayment);
      } else {
        await ref.read(paymentControllerProvider).createScheduledPayment(
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          dueDate: _selectedDate,
          frequency: _selectedFrequency,
          reminders: _selectedReminders.toList(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Pago actualizado con éxito' : 'Pago programado con éxito'), 
            backgroundColor: Colors.green
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Pago' : 'Nuevo Pago Programado'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del pago (Ej. Internet)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? 'El nombre es requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'El monto es requerido';
                      if (double.tryParse(value) == null) return 'Ingresa un número válido';
                      if (double.parse(value) <= 0) return 'El monto debe ser mayor a 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text('Fecha de vencimiento', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat.yMMMd('es').format(_selectedDate)),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Frecuencia', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedFrequency,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('Una sola vez')),
                      DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                      DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                      DropdownMenuItem(value: 'yearly', child: Text('Anual')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedFrequency = val);
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text('Recordatorios (días de anticipación)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: [1, 3, 7].map((days) {
                      final isSelected = _selectedReminders.contains(days);
                      return FilterChip(
                        label: Text('$days día(s)'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedReminders.add(days);
                            } else {
                              _selectedReminders.remove(days);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _savePayment,
                      child: Text(_isEditMode ? 'Actualizar Pago' : 'Guardar Pago', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
