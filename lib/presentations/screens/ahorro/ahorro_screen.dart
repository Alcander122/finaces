// ahorro_screen.dart
import 'package:finances/core/data/models/objetivo_ahorro.dart';
import 'package:finances/core/data/services/servicio_ahorro.dart';
import 'package:finances/core/data/utils/ahorro_validator.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/presentations/widgets/custom_form_container.dart';
import 'package:finances/presentations/widgets/app_input_style.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Importa tus widgets locales
import 'detalles_transacciones.dart';
import 'dialogo_transaccion.dart';
import 'widgets/elemento_objetivo_ahorro.dart';

class AhorroScreen extends StatefulWidget {
  const AhorroScreen({super.key});

  @override
  AhorroScreenState createState() => AhorroScreenState();
}

class AhorroScreenState extends State<AhorroScreen> {
  final AhorroService _ahorroService = AhorroService();

  // Variables del formulario
  late GlobalKey<FormState> _metaFormKey;
  late TextEditingController _nombreCtrl;
  late TextEditingController _montoCtrl;
  late TextEditingController _fechaCtrl;
  late DateTime _fechaObjetivo;
  late AhorroValidator _validator;

  @override
  void initState() {
    super.initState();
    _metaFormKey = GlobalKey<FormState>();
    _nombreCtrl = TextEditingController();
    _montoCtrl = TextEditingController();
    _fechaCtrl = TextEditingController();
    _validator = AhorroValidator();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    _fechaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Themes.light,
      appBar: const AppBarFinances(
        title: 'Metas',
        showProfileIcon: false,
      ),
      resizeToAvoidBottomInset: true,
      body: StreamBuilder<List<ObjetivoAhorro>>(
        stream: _ahorroService.obtenerMetas(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final metas = snapshot.data!;
          if (metas.isEmpty) {
            return const Center(child: Text('No hay metas de ahorro creadas'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: metas.length,
            itemBuilder: (context, index) {
              final meta = metas[index];
              return ElementoObjetivoAhorro(
                meta: meta,
                onTransaccion: (tipo) =>
                    _mostrarDialogo(context, meta.id!, tipo),
                onVerDetalles: () =>
                    _mostrarDetallesTransacciones(context, meta),
                onEliminar: () async => await _eliminarMeta(context, meta),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNuevaMeta(context),
        backgroundColor: Themes.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // === DIÁLOGO DE TRANSACCIÓN ===
  Future<void> _mostrarDialogo(
      BuildContext context, String metaId, String tipo) async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<List<ObjetivoAhorro>>(
          future: _ahorroService.obtenerMetas().first,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return AlertDialog(
                title: const Text('Error'),
                content: const Text('No se pudo cargar la meta'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            }

            final meta = snapshot.data!.firstWhere((m) => m.id == metaId);
            return DialogoTransaccion(
              onGuardar: (monto, descripcion) {
                if (tipo == 'deposito') {
                  final restante = meta.montoRestante;
                  if (monto > restante) {
                    UIHelpers.showErrorSnackBar(
                      context: context,
                      message:
                          'No puedes depositar más de ${UIHelpers.formatCurrency(restante)}',
                    );
                    return;
                  }
                }
                _manejarTransaccion(
                    dialogContext, metaId, tipo, monto, descripcion);
              },
              maxMonto:
                  tipo == 'retiro' ? meta.montoActual : meta.montoRestante,
              titulo:
                  tipo == 'retiro' ? 'Realizar Retiro' : 'Realizar Depósito',
            );
          },
        );
      },
    );
  }

  void _manejarTransaccion(BuildContext dialogContext, String metaId,
      String tipo, double monto, String descripcion) {
    _ahorroService
        .agregarTransaccion(
      metaId: metaId,
      tipo: tipo,
      monto: monto,
      descripcion: descripcion,
    )
        .then((_) {
      Navigator.pop(dialogContext);
      UIHelpers.showSuccessSnackBar(
        context: context,
        message: 'Operación exitosa',
      );
    }).catchError((error) {
      UIHelpers.showErrorSnackBar(
        context: context,
        message: 'Error: $error',
      );
    });
  }

  // === ELIMINAR META ===
  Future<void> _eliminarMeta(BuildContext context, ObjetivoAhorro meta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar meta'),
        content: Text('¿Seguro que quieres eliminar "${meta.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _ahorroService.eliminarMeta(meta.id!);
        UIHelpers.showSuccessSnackBar(
          context: context,
          message: 'Meta eliminada',
        );
      } catch (e) {
        UIHelpers.showErrorSnackBar(
          context: context,
          message: 'Error: $e',
        );
      }
    }
  }

  // === FORMULARIO NUEVA META ===
  void _mostrarDialogoNuevaMeta(BuildContext context) {
    _nombreCtrl.clear();
    _montoCtrl.clear();
    _fechaObjetivo = DateTime.now().add(const Duration(days: 30));
    _fechaCtrl.text = DateFormat('dd/MM/yyyy').format(_fechaObjetivo);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: CustomFormContainer(
              formKey: _metaFormKey,
              onCancel: () => Navigator.pop(dialogContext),
              onSave: () => _guardarMeta(dialogContext, context),
              saveButtonText: 'Guardar',
              cancelButtonText: 'Cancelar',
              children: [
                const Text(
                  'Nueva Meta de Ahorro',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Themes.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Nombre
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: AppInputStyle.textField(
                    label: 'Nombre de la Meta',
                    suffixIcon: const Icon(Icons.title),
                  ),
                  validator: _validator.validateNombre,
                ),
                const SizedBox(height: 12),

                // Monto
                TextFormField(
                  controller: _montoCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: AppInputStyle.textField(
                    label: 'Monto Objetivo',
                    suffixIcon: const Icon(Icons.attach_money),
                  ),
                  onChanged: (value) {
                    final clean = value.replaceAll(RegExp(r'[^\d]'), '');
                    if (clean.isEmpty) {
                      _montoCtrl.text = '';
                      return;
                    }
                    final formatted =
                        UIHelpers.formatCurrency(double.parse(clean));
                    if (formatted != _montoCtrl.text) {
                      _montoCtrl.text = formatted;
                      _montoCtrl.selection =
                          TextSelection.collapsed(offset: formatted.length);
                    }
                  },
                  validator: (value) {
                    final clean = value?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
                    return _validator.validateMonto(
                        clean.isEmpty ? null : clean, null);
                  },
                ),
                const SizedBox(height: 12),

                // Fecha
                TextFormField(
                  controller: _fechaCtrl,
                  readOnly: true,
                  decoration: AppInputStyle.textField(
                    label: 'Fecha Objetivo',
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _fechaObjetivo,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _fechaObjetivo = picked;
                        _fechaCtrl.text =
                            DateFormat('dd/MM/yyyy').format(picked);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === GUARDAR META ===
  void _guardarMeta(BuildContext dialogContext, BuildContext scaffoldContext) {
    if (!_metaFormKey.currentState!.validate()) return;

    final nombre = _nombreCtrl.text.trim();
    final montoLimpio = _montoCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
    final montoObjetivo = double.tryParse(montoLimpio) ?? 0;
    final ahora = DateTime.now();

    _ahorroService
        .crearMeta(
      nombre: nombre,
      montoObjetivo: montoObjetivo,
      fechaObjetivo: _fechaObjetivo,
      fechaCreacion: ahora,
    )
        .then((_) {
      Navigator.pop(dialogContext);
      UIHelpers.showSuccessSnackBar(
        context: scaffoldContext,
        message: 'Meta creada correctamente',
      );
    }).catchError((error) {
      UIHelpers.showErrorSnackBar(
        context: scaffoldContext,
        message: 'Error: $error',
      );
    });
  }

  // === NAVEGAR A DETALLES ===
  void _mostrarDetallesTransacciones(
      BuildContext context, ObjetivoAhorro meta) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetallesTransacciones(meta: meta),
      ),
    );
  }
}
