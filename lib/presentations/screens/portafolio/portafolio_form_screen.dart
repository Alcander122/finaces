import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:finances/core/data/models/portafolio_model.dart';
import 'package:finances/core/data/providers/portafolio_provider.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/widgets/custom_form_container.dart';
import 'package:finances/presentations/widgets/app_input_style.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/errors/handlers/db_error_handler.dart';

class PortafolioFormScreen extends ConsumerStatefulWidget {
  final String userId;
  final Portafolio? portafolio;

  const PortafolioFormScreen({
    super.key,
    required this.userId,
    this.portafolio,
  });

  @override
  PortafolioFormScreenState createState() => PortafolioFormScreenState();
}

class PortafolioFormScreenState extends ConsumerState<PortafolioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _notaController = TextEditingController();
  late DateTime _fechaCreacion;

  @override
  void initState() {
    super.initState();
    _fechaCreacion = widget.portafolio?.fechaCreacion ?? DateTime.now();

    if (widget.portafolio != null) {
      _nombreController.text = widget.portafolio!.nombre;
      _descripcionController.text = widget.portafolio!.descripcion ?? '';
      _notaController.text = widget.portafolio!.nota;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  void _guardarPortafolio() {
    if (!_formKey.currentState!.validate()) return;

    final portafolio = Portafolio(
      id: widget.portafolio?.id ?? const Uuid().v4(),
      userId: widget.userId,
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.isNotEmpty
          ? _descripcionController.text.trim()
          : null,
      fechaCreacion: _fechaCreacion,
      nota: _notaController.text.trim(),
    );

    final service = ref.read(portafolioServiceProvider);
    final future = widget.portafolio == null
        ? service.agregarPortafolio(widget.userId, portafolio)
        : service.actualizarPortafolio(widget.userId, portafolio);

    future.then((_) {
      if (mounted) {
        Navigator.pop(context);
        UIHelpers.showSuccessSnackBar(
          context: context,
          message: widget.portafolio == null
              ? 'Portafolio creado correctamente'
              : 'Portafolio actualizado correctamente',
        );
      }
    }).catchError((error) {
      if (mounted) {
        final friendlyError = DbErrorHandler.handle(error);
        UIHelpers.showErrorSnackBar(
          context: context,
          message: friendlyError,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Themes.light,
      appBar: AppBar(
        backgroundColor: Themes.primary,
        foregroundColor: Colors.white,
        title: Text(
          widget.portafolio == null ? "Nuevo Portafolio" : "Editar Portafolio",
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: CustomFormContainer(
          formKey: _formKey,
          onCancel: () => Navigator.pop(context),
          onSave: _guardarPortafolio,
          saveButtonText: 'Guardar',
          cancelButtonText: 'Cancelar',
          children: [
            // Título
            Text(
              widget.portafolio == null
                  ? "Crear Portafolio"
                  : "Editar Portafolio",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Themes.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Campo: Nombre
            TextFormField(
              controller: _nombreController,
              decoration: AppInputStyle.textField(
                label: 'Nombre *',
                suffixIcon: const Icon(Icons.folder),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return ErrorStrings.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Campo: Descripción
            TextFormField(
              controller: _descripcionController,
              decoration: AppInputStyle.textField(
                label: 'Descripción',
                suffixIcon: const Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // Campo: Nota
            TextFormField(
              controller: _notaController,
              decoration: AppInputStyle.textField(
                label: 'Nota *',
                suffixIcon: const Icon(Icons.note),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return ErrorStrings.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Campo: Fecha de Creación
            TextFormField(
              readOnly: true,
              decoration: AppInputStyle.textField(
                label: 'Fecha de Creación',
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              controller: TextEditingController(
                text: DateFormat('dd/MM/yyyy').format(_fechaCreacion),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fechaCreacion,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _fechaCreacion = picked;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

