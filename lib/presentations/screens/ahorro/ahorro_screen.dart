// 📱 lib/presentations/screens/Ahorro/ahorro_screen.dart
// ============================================================================
// PANTALLA: AhorroScreen - VERSIÓN 100% ESTABLE (ADIÓS AL ERROR DE CONTEXT)
// ============================================================================

import 'package:finances/core/data/models/objetivo_ahorro.dart';
import 'package:finances/core/data/services/servicio_ahorro.dart';
import 'package:finances/core/data/utils/ahorro_validator.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';

import 'package:finances/presentations/screens/Ahorro/detalles_transacciones.dart';
import 'package:finances/presentations/screens/ahorro/dialogo_nueva_meta_mejorado.dart';
import 'package:finances/presentations/screens/ahorro/dialogo_transaccion.dart';
import 'package:finances/presentations/screens/ahorro/widgets/elemento_objetivo_ahorro_mejorado.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:flutter/material.dart';

class AhorroScreen extends StatefulWidget {
  const AhorroScreen({super.key});

  @override
  AhorroScreenState createState() => AhorroScreenState();
}

class AhorroScreenState extends State<AhorroScreen> {
  final AhorroService _ahorroService = AhorroService();
  late AhorroValidator validator;

  @override
  void initState() {
    super.initState();
    validator = AhorroValidator();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Themes.light,
      appBar: const AppBarFinances(title: 'Metas', showProfileIcon: false),
      resizeToAvoidBottomInset: true,
      body: StreamBuilder<List<ObjetivoAhorro>>(
        stream: _ahorroService.obtenerMetas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final metas = snapshot.data ?? [];

          if (metas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.savings_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No hay metas de ahorro creadas'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _mostrarDialogoNuevaMeta,
                    icon: const Icon(Icons.add),
                    label: const Text('Crear primera meta'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: metas.length,
            itemBuilder: (context, index) {
              final meta = metas[index];

              return ElementoObjetivoAhorroMejorado(
                meta: meta,
                onTransaccion: (tipo) =>
                    _mostrarDialogoTransaccion(meta.id!, tipo),
                onVerDetalles: () => _mostrarDetallesTransacciones(meta),
                onEliminar: () => _eliminarMeta(meta),
                mostrarDesglose: true,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNuevaMeta,
        backgroundColor: Themes.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ============================================================================
  // NUEVA META
  // ============================================================================
  void _mostrarDialogoNuevaMeta() {
    showDialog(
      context: context,
      builder: (_) => DialogoNuevaMetaMejorado(
        onGuardar: (nombre, monto, fecha) {
          _ahorroService
              .crearMeta(
            nombre: nombre,
            montoObjetivo: monto,
            fechaObjetivo: fecha,
            fechaCreacion: DateTime.now(),
          )
              .then((_) {
            Navigator.pop(context); // Cerramos el diálogo desde aquí

            if (!mounted) return;
            UIHelpers.showSuccessSnackBar(
                context: context, message: 'Meta "$nombre" creada');
          }).catchError((error) {
            if (!mounted) return;
            UIHelpers.showErrorSnackBar(
                context: context, message: 'Error: $error');
          });
        },
      ),
    );
  }

  // ============================================================================
  // TRANSACCIÓN (depósito/retiro)
  // ============================================================================
  void _mostrarDialogoTransaccion(String metaId, String tipo) {
    showDialog(
      context: context,
      builder: (_) {
        return FutureBuilder<List<ObjetivoAhorro>>(
          future: _ahorroService.obtenerMetas().first,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return AlertDialog(
                title: const Text('Error'),
                content: const Text('No se pudo cargar la meta'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'))
                ],
              );
            }

            final meta = snapshot.data!.firstWhere((m) => m.id == metaId);

            return DialogoTransaccion(
              titulo:
                  tipo == 'retiro' ? 'Realizar Retiro' : 'Realizar Depósito',
              maxMonto:
                  tipo == 'retiro' ? meta.montoActual : meta.montoRestante,
              onGuardar: (monto, descripcion) {
                // Validación de depósito excesivo
                if (tipo == 'deposito' && monto > meta.montoRestante) {
                  if (!mounted) return;
                  UIHelpers.showErrorSnackBar(
                    context: context,
                    message:
                        'No puedes depositar más de ${UIHelpers.formatCurrency(meta.montoRestante)}',
                  );
                  return;
                }

                // Procesar transacción
                _ahorroService
                    .agregarTransaccion(
                  metaId: metaId,
                  tipo: tipo,
                  monto: monto,
                  descripcion: descripcion,
                )
                    .then((_) {
                  Navigator.pop(context);

                  if (!mounted) return;
                  UIHelpers.showSuccessSnackBar(
                    context: context,
                    message: tipo == 'deposito'
                        ? 'Depósito realizado'
                        : 'Retiro realizado',
                  );
                }).catchError((error) {
                  if (!mounted) return;
                  UIHelpers.showErrorSnackBar(
                      context: context, message: 'Error: $error');
                });
              },
            );
          },
        );
      },
    );
  }

  // ============================================================================
  // DETALLES
  // ============================================================================
  void _mostrarDetallesTransacciones(ObjetivoAhorro meta) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetallesTransacciones(meta: meta)),
    );
  }

  // ============================================================================
  // ELIMINAR
  // ============================================================================
  Future<void> _eliminarMeta(ObjetivoAhorro meta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar meta'),
        content: Text('¿Eliminar "${meta.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _ahorroService.eliminarMeta(meta.id!);

        if (!mounted) return;
        UIHelpers.showSuccessSnackBar(
            context: context, message: 'Meta eliminada');
      } catch (e) {
        if (!mounted) return;
        UIHelpers.showErrorSnackBar(
            context: context, message: 'Error al eliminar');
      }
    }
  }
}
