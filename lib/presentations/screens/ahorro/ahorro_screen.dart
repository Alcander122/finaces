// 📱 lib/presentations/screens/Ahorro/ahorro_screen.dart
// ============================================================================
// PANTALLA PRINCIPAL DE AHORROS - REFACTORIZADA CON RIVERPOD CONTROLLER
// ============================================================================

import 'package:finances/core/data/models/objetivo_ahorro.dart';
import 'package:finances/core/data/providers/ahorro_provider.dart';
import 'package:finances/core/errors/error_strings.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/screens/Ahorro/detalles_transacciones.dart';
import 'package:finances/presentations/screens/ahorro/dialogo_nueva_meta_mejorado.dart';
import 'package:finances/presentations/screens/ahorro/dialogo_transaccion.dart';
import 'package:finances/presentations/screens/ahorro/widgets/elemento_objetivo_ahorro_mejorado.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AhorroScreen extends ConsumerStatefulWidget {
  const AhorroScreen({super.key});
  @override
  AhorroScreenState createState() => AhorroScreenState();
}

class AhorroScreenState extends ConsumerState<AhorroScreen> {
  @override
  Widget build(BuildContext context) {
    // Escuchamos el stream centralizado de metas en tiempo real
    final metasAsync = ref.watch(metasAhorroProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBgColor,
      appBar: const AppBarFinances(title: 'Metas', showProfileIcon: false),
      resizeToAvoidBottomInset: true,
      body: metasAsync.when(
        data: (metas) {
          if (metas.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Themes.primary.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.savings_outlined,
                        size: 72,
                        color: context.colors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No hay metas de ahorro creadas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.titleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Empieza a planificar tu futuro financiero hoy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _mostrarDialogoNuevaMeta,
                      icon: const Icon(Icons.add),
                      label: const Text('Crear mi primera meta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Themes.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: metas.length,
            itemBuilder: (_, i) => ElementoObjetivoAhorroMejorado(
              meta: metas[i],
              onTransaccion: (tipo) =>
                  _mostrarDialogoTransaccion(metas[i].id!, tipo),
              onVerDetalles: () => _mostrarDetallesTransacciones(metas[i]),
              onEliminar: () => _eliminarMeta(metas[i]),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Themes.primary,
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  ErrorStrings.loadFailed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNuevaMeta,
        backgroundColor: Themes.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ============================================================================
  // MOSTRAR DIÁLOGO CREAR NUEVA META
  // ============================================================================
  void _mostrarDialogoNuevaMeta() {
    showDialog(
      context: context,
      barrierDismissible: false, // Forzar uso de Cancelar para evitar estados inconsistentes
      builder: (dialogContext) => const DialogoNuevaMetaMejorado(),
    );
  }

  // ============================================================================
  // MOSTRAR DIÁLOGO TRANSACCIÓN (DEPÓSITO / RETIRO)
  // ============================================================================
  void _mostrarDialogoTransaccion(String metaId, String tipo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final metasActuales = ref.read(metasAhorroProvider).value;
        
        if (metasActuales == null || metasActuales.isEmpty) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(ErrorStrings.loadFailed),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              )
            ],
          );
        }

        final meta = metasActuales.firstWhere(
          (m) => m.id == metaId,
          orElse: () => metasActuales.first,
        );

        return DialogoTransaccion(
          metaId: metaId,
          tipo: tipo,
          maxMonto: tipo == 'retiro' ? meta.montoActual : meta.montoRestante,
        );
      },
    );
  }

  // ============================================================================
  // VER DETALLES DE TRANSACCIONES
  // ============================================================================
  void _mostrarDetallesTransacciones(ObjetivoAhorro meta) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetallesTransacciones(meta: meta)),
    );
  }

  // ============================================================================
  // ELIMINAR META DE AHORRO
  // ============================================================================
  Future<void> _eliminarMeta(ObjetivoAhorro meta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar meta'),
          ],
        ),
        content: Text('¿Estás seguro de que deseas eliminar la meta "${meta.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Mostrar diálogo de carga simple
      if (!mounted) return;
      UIHelpers.showLoadingDialog(context, message: 'Eliminando meta...');

      try {
        await ref.read(ahorroControllerProvider.notifier).eliminarMeta(meta.id!);
        if (!mounted) return;
        UIHelpers.hideLoadingDialog(context);
        UIHelpers.showSuccessSnackBar(
          context: context,
          message: 'Meta "${meta.nombre}" eliminada exitosamente.',
        );
      } catch (e) {
        if (!mounted) return;
        UIHelpers.hideLoadingDialog(context);
        UIHelpers.showErrorSnackBar(
          context: context,
          message: e.toString(),
        );
      }
    }
  }
}