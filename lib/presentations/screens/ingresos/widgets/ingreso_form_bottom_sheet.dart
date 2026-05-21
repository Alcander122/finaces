import 'package:finances/core/data/services/ingresos_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/core/errors/error_strings.dart';

class IngresoFormBottomSheet extends ConsumerStatefulWidget {
  final Ingreso? ingresoToEdit;

  const IngresoFormBottomSheet({super.key, this.ingresoToEdit});

  @override
  ConsumerState<IngresoFormBottomSheet> createState() =>
      _IngresoFormBottomSheetState();
}

class _IngresoFormBottomSheetState
    extends ConsumerState<IngresoFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _conceptoController;
  late TextEditingController _valorController;
  String _categoria = 'Salario';

  final List<String> _categorias = [
    'Salario',
    'Negocio',
    'Inversiones',
    'Regalos',
    'Otros'
  ];

  @override
  void initState() {
    super.initState();
    _conceptoController =
        TextEditingController(text: widget.ingresoToEdit?.concepto ?? '');
    _valorController = TextEditingController(
        text: widget.ingresoToEdit?.valor.toString() ?? '');

    if (widget.ingresoToEdit != null &&
        _categorias.contains(widget.ingresoToEdit!.categoria)) {
      _categoria = widget.ingresoToEdit!.categoria;
    }
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final nuevoIngreso = Ingreso(
      id: widget.ingresoToEdit?.id ?? '', // Asignado en Firestore si es nuevo
      fecha: widget.ingresoToEdit?.fecha ?? DateTime.now(),
      fechaIngreso: widget.ingresoToEdit?.fechaIngreso ?? DateTime.now(),
      quincena: widget.ingresoToEdit?.quincena ?? '1',
      categoria: _categoria,
      concepto: _conceptoController.text.trim(),
      // num.tryParse asegura que no haga crash si el usuario ingresa decimales
      valor: int.tryParse(_valorController.text.trim()) ?? 0,
    );

    final controller = ref.read(ingresosControllerProvider.notifier);
    if (widget.ingresoToEdit == null) {
      await controller.agregarIngreso(nuevoIngreso);
    } else {
      await controller.actualizarIngreso(nuevoIngreso);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isEditing = widget.ingresoToEdit != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Editar Ingreso' : 'Nuevo Ingreso',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _conceptoController,
              decoration: const InputDecoration(
                labelText: 'Concepto',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                prefixIcon: Icon(Icons.description_outlined),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? ErrorStrings.requiredField
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valorController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return ErrorStrings.requiredField;
                }
                final numericValue = num.tryParse(value);
                if (numericValue == null || numericValue <= 0) {
                  return ErrorStrings.invalidAmount;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              items: _categorias
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _categoria = val!),
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                prefixIcon: Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: _submit,
              child: Text(
                isEditing ? 'ACTUALIZAR' : 'GUARDAR',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
