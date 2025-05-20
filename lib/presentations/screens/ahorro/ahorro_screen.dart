import 'package:finances/core/data/models/objetivo_ahorro.dart';
import 'package:finances/core/data/services/servicio_ahorro.dart';
import 'package:finances/core/data/utils/ahorro_validator.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Importa tus archivos locales
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Ahorros'),
      ),
      // Permite que el contenido se ajuste cuando aparece el teclado
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
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNuevaMeta(context),
        child: const Icon(Icons.add),
      ),
    );
  }

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
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text('Error: ${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return AlertDialog(
                title: const Text('Sin Metas'),
                content: const Text('No hay metas disponibles'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            }
            final metas = snapshot.data!;
            final metaSeleccionada = metas.firstWhere((m) => m.id == metaId);

            return DialogoTransaccion(
              onGuardar: (monto, descripcion) => _manejarTransaccion(
                  dialogContext, metaId, tipo, monto, descripcion),
              maxMonto: tipo == 'retiro' ? metaSeleccionada.montoActual : null,
              titulo:
                  tipo == 'retiro' ? 'Realizar Retiro' : 'Nueva Transacción',
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operación exitosa')),
      );
    }).catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    });
  }

  void _mostrarDialogoNuevaMeta(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final montoController = TextEditingController();
    final fechaController = TextEditingController();
    final AhorroValidator validator = AhorroValidator();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Nueva Meta de Ahorro'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Meta',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => validator.validateNombre(value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto Objetivo',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => validator.validateMonto(value, null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: fechaController,
                decoration: const InputDecoration(
                  labelText: 'Fecha Objetivo',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      fechaController.text =
                          DateFormat('yyyy-MM-dd').format(picked);
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final nombre = nombreController.text.trim();
                final montoObjetivo = double.parse(montoController.text);
                final fechaObjetivo = DateTime.parse(fechaController.text);
                _ahorroService
                    .crearMeta(
                  nombre: nombre,
                  montoObjetivo: montoObjetivo,
                  fechaObjetivo: fechaObjetivo,
                )
                    .then((_) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meta creada correctamente')),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $error')),
                  );
                });
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  /// Navegación a la pantalla de detalles de transacciones
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
