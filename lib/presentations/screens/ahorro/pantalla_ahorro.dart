import 'package:finances/core/data/models/objetivo_ahorro.dart';
import 'package:finances/core/data/services/servicio_ahorro.dart';
import 'package:finances/core/data/utils/ahorro_validator.dart';
import 'package:finances/presentations/widgets/elemento_objetivo_ahorro.dart';
import 'package:flutter/material.dart';
import 'package:finances/presentations/widgets/dialogo_transaccion.dart';
import 'package:intl/intl.dart';

// Clase principal que extiende ConsumerStatefulWidget
class AhorroScreen extends StatefulWidget {
  const AhorroScreen({super.key});

  @override
  _PantallaAhorroState createState() => _PantallaAhorroState();
}

// Estado de la pantalla que extiende ConsumerState
class _PantallaAhorroState extends State<AhorroScreen> {
  // Inicializa _ahorroService directamente
  final AhorroService _ahorroService = AhorroService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Ahorros'),
      ),
      body: StreamBuilder<List<ObjetivoAhorro>>(
        stream: _ahorroService.obtenerMetas(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final meta = snapshot.data![index];
              return ElementoObjetivoAhorro(
                meta: meta,
                onTransaccion: (tipo) =>
                    _mostrarDialogo(context, meta.id!, tipo),
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

  // Método para mostrar el diálogo de transacción
  Future<void> _mostrarDialogo(
      BuildContext context, String metaId, String tipo) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Transacción'),
        content: FutureBuilder<List<ObjetivoAhorro>>(
          future: _ahorroService.obtenerMetas().first,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay metas disponibles'));
            }

            final metas = snapshot.data!;
            final metaSeleccionada =
                metas.firstWhere((meta) => meta.id == metaId);

            return DialogoTransaccion(
              onGuardar: (monto) =>
                  _manejarTransaccion(context, metaId, tipo, monto),
              maxMonto: tipo == 'retiro' ? metaSeleccionada.montoActual : null,
            );
          },
        ),
      ),
    );
  }

  // Método para manejar la transacción
  void _manejarTransaccion(
      BuildContext context, String metaId, String tipo, double monto) {
    _ahorroService
        .agregarTransaccion(
      metaId: metaId,
      tipo: tipo,
      monto: monto,
    )
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operación exitosa')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    });
  }

  // Método para mostrar el diálogo de nueva meta
  void _mostrarDialogoNuevaMeta(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _nombreController = TextEditingController();
    final _montoController = TextEditingController();
    final _fechaController = TextEditingController();
    final AhorroValidator _validator = AhorroValidator();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Meta de Ahorro'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration:
                      const InputDecoration(labelText: 'Nombre de la Meta'),
                  validator: (value) => _validator.validateNombre(value),
                ),
                TextFormField(
                  controller: _montoController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Monto Objetivo'),
                  validator: (value) => _validator.validateMonto(value, null),
                ),
                TextFormField(
                  controller: _fechaController,
                  decoration:
                      const InputDecoration(labelText: 'Fecha Objetivo'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _fechaController.text =
                            DateFormat('yyyy-MM-dd').format(picked);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final nombre = _nombreController.text;
                final montoObjetivo = double.parse(_montoController.text);
                final fechaObjetivo = DateTime.parse(_fechaController.text);

                _ahorroService
                    .crearMeta(
                  nombre: nombre,
                  montoObjetivo: montoObjetivo,
                  fechaObjetivo: fechaObjetivo,
                )
                    .then((_) {
                  Navigator.pop(context);
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
}
