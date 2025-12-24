// 🎨 presentations/screens/ahorro/elemento_objetivo_ahorro_mejorado.dart
// ============================================================================
// WIDGET: ElementoObjetivoAhorroMejorado - MUESTRA TODAS LAS METAS (INCLUSO VENCIDAS)
// ============================================================================

import 'package:finances/core/data/models/objetivo_ahorro.dart';
import 'package:finances/core/data/utils/ahorro_calculator.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:flutter/material.dart';

class ElementoObjetivoAhorroMejorado extends StatelessWidget {
  final ObjetivoAhorro meta;
  final Function(String) onTransaccion;
  final Function() onVerDetalles;
  final Function() onEliminar;
  final bool mostrarDesglose;

  const ElementoObjetivoAhorroMejorado({
    super.key,
    required this.meta,
    required this.onTransaccion,
    required this.onVerDetalles,
    required this.onEliminar,
    this.mostrarDesglose = true,
  });

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final bool estaVencida = meta.fechaObjetivo.isBefore(ahora);
    final bool montoValido = meta.montoObjetivo > 0;

    // Si el monto es inválido, al menos mostramos la meta con advertencia
    if (!montoValido) {
      return _tarjetaMetaInvalida(context, 'Monto inválido');
    }

    // Cálculo del desglose (seguro)
    late final AhorroDesglose desglose;
    try {
      desglose = AhorroCalculator.calcularDesglose(
        montoObjetivo: meta.montoObjetivo,
        fechaObjetivo: meta.fechaObjetivo,
      );
    } catch (e) {
      desglose = AhorroDesglose.invalido(
        montoObjetivo: meta.montoObjetivo,
        fechaInicio: ahora,
        fechaObjetivo: meta.fechaObjetivo,
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Builder(builder: (safeContext) {
          final theme = Theme.of(safeContext);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombre de la meta
              Center(
                child: Text(
                  meta.nombre,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              // Indicador si está vencida
              if (estaVencida)
                const Center(
                  child: Text(
                    '⏰ Fecha objetivo vencida',
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ),
              const SizedBox(height: 12),

              // Barra de progreso (roja si vencida, verde si activa)
              LinearProgressIndicator(
                value: (meta.progreso / 100).clamp(0.0, 1.0),
                minHeight: 12,
                color: estaVencida
                    ? Colors.red.shade400
                    : (meta.progreso >= 100 ? Colors.green : Colors.green),
                backgroundColor: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 12),

              // Monto actual vs objetivo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    UIHelpers.formatCurrency(meta.montoActual),
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: estaVencida ? Colors.red[800] : Colors.green[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'de ${UIHelpers.formatCurrency(meta.montoObjetivo)}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Estado de progreso
              Center(
                child: Text(
                  meta.progreso >= 100
                      ? '🎉 ¡Meta cumplida!'
                      : estaVencida
                          ? 'Meta vencida'
                          : 'Progreso: ${meta.progreso.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: meta.progreso >= 100
                        ? Colors.green
                        : estaVencida
                            ? Colors.red
                            : Colors.blueGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Desglose: solo si es válido y queremos mostrarlo
              if (mostrarDesglose && desglose.esValido)
                _construirSeccionDesglose(safeContext, desglose, estaVencida)
              else if (mostrarDesglose)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    estaVencida
                        ? 'El plan de ahorro ya no aplica (fecha vencida)'
                        : 'Plan de ahorro no disponible',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 16),

              // Botones de acción
              OverflowBar(
                alignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Puedes desactivar depósito/retiro si está vencida, o dejarlos activos
                  IconButton(
                    tooltip: estaVencida ? 'Meta vencida' : 'Depositar',
                    icon: Icon(Icons.add_circle,
                        color: estaVencida ? Colors.grey : Colors.green),
                    onPressed:
                        estaVencida ? null : () => onTransaccion('deposito'),
                  ),
                  IconButton(
                    tooltip: estaVencida ? 'Meta vencida' : 'Retirar',
                    icon: Icon(Icons.remove_circle,
                        color: estaVencida ? Colors.grey : Colors.red),
                    onPressed:
                        estaVencida ? null : () => onTransaccion('retiro'),
                  ),
                  IconButton(
                    tooltip: 'Ver detalles',
                    icon: const Icon(Icons.info_outline, color: Colors.blue),
                    onPressed: onVerDetalles,
                  ),
                  IconButton(
                    tooltip: 'Eliminar meta',
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onEliminar,
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  // Tarjeta para metas con monto inválido (raro, pero por seguridad)
  Widget _tarjetaMetaInvalida(BuildContext context, String mensaje) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(meta.nombre,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Text('⚠️ $mensaje', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onEliminar),
          ],
        ),
      ),
    );
  }

  // Sección de desglose (con indicador si está vencida)
  Widget _construirSeccionDesglose(
      BuildContext context, AhorroDesglose desglose, bool estaVencida) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: estaVencida ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: estaVencida ? Colors.red.shade200 : Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up,
                  color:
                      estaVencida ? Colors.red.shade700 : Colors.blue.shade700,
                  size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Plan de Ahorro',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: estaVencida
                          ? Colors.red.shade700
                          : Colors.blue.shade700),
                ),
              ),
              Text(
                desglose.mensajeTiempoRestante,
                style: TextStyle(
                    fontSize: 11,
                    color: estaVencida
                        ? Colors.red.shade600
                        : Colors.blue.shade600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.3,
            children: [
              _construirTarjetaAhorro(
                  'Diario', desglose.ahorrosDiarios, Icons.calendar_today),
              _construirTarjetaAhorro(
                  'Semanal', desglose.ahorrosSemanal, Icons.date_range),
              _construirTarjetaAhorro(
                  'Quincenal', desglose.ahorrosQuincenal, Icons.event_note),
              _construirTarjetaAhorro(
                  'Mensual', desglose.ahorrosMensual, Icons.calendar_month),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: estaVencida ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: estaVencida
                      ? Colors.red.shade300
                      : Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: estaVencida
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                    size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    estaVencida
                        ? 'La meta ya venció'
                        : '💡 Recomendado: ${_obtenerNombrePeriodo(desglose.periodoRecomendado)}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: estaVencida
                            ? Colors.red.shade700
                            : Colors.green.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaAhorro(String periodo, double monto, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade100)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 16, color: Colors.blue.shade600),
          const SizedBox(height: 4),
          Text(periodo,
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(UIHelpers.formatCurrency(monto),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700)),
        ],
      ),
    );
  }

  String _obtenerNombrePeriodo(String periodo) {
    return switch (periodo) {
      'diario' => 'Ahorrar diariamente',
      'semanal' => 'Ahorrar semanalmente',
      'quincenal' => 'Ahorrar quincenalmente',
      'mensual' => 'Ahorrar mensualmente',
      _ => 'Período personalizado',
    };
  }
}
