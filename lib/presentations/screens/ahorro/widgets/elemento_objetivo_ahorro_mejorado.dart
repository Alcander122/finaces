// 🎨 presentations/screens/ahorro/elemento_objetivo_ahorro_mejorado.dart
// ============================================================================
// WIDGET: Muestra cada meta de ahorro con desglose REALISTA (solo lo pendiente)
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

    if (!montoValido) {
      return _tarjetaMetaInvalida(context, 'Monto inválido');
    }

    // 🔥 Cálculo considerando lo ya ahorrado
    late final AhorroDesglose desglose;
    try {
      desglose = AhorroCalculator.calcularDesglose(
        montoObjetivo: meta.montoObjetivo,
        fechaObjetivo: meta.fechaObjetivo,
        montoActual: meta.montoActual, // ← CLAVE: solo lo pendiente
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nombre
            Center(
              child: Text(
                meta.nombre,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            // Vencida
            if (estaVencida)
              const Center(
                child: Text('⏰ Fecha objetivo vencida',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 12),

            // Progreso
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

            // Montos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(UIHelpers.formatCurrency(meta.montoActual),
                    style: TextStyle(
                        color: Colors.green[800], fontWeight: FontWeight.w600)),
                Text('de ${UIHelpers.formatCurrency(meta.montoObjetivo)}'),
              ],
            ),
            const SizedBox(height: 8),

            // Estado
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
                            : Colors.blueGrey),
              ),
            ),
            const SizedBox(height: 16),

            // Desglose (solo si es válido)
            if (mostrarDesglose && desglose.esValido)
              _construirSeccionDesglose(
                  context, desglose, estaVencida, meta.montoActual > 0)
            else if (mostrarDesglose)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  estaVencida
                      ? 'El plan de ahorro ya no aplica'
                      : 'Plan no disponible',
                  style: const TextStyle(color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 16),

            // Botones
            OverflowBar(
              alignment: MainAxisAlignment.spaceEvenly,
              children: [
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
                  onPressed: estaVencida ? null : () => onTransaccion('retiro'),
                ),
                IconButton(
                    tooltip: 'Detalles',
                    icon: const Icon(Icons.info_outline, color: Colors.blue),
                    onPressed: onVerDetalles),
                IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onEliminar),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirSeccionDesglose(BuildContext context,
      AhorroDesglose desglose, bool vencida, bool tieneProgreso) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: vencida ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: vencida ? Colors.red.shade200 : Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up,
                  color: vencida ? Colors.red.shade700 : Colors.blue.shade700,
                  size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tieneProgreso ? 'Plan de ahorro restante' : 'Plan de ahorro',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          vencida ? Colors.red.shade700 : Colors.blue.shade700),
                ),
              ),
              Text(desglose.mensajeTiempoRestante,
                  style: TextStyle(
                      color: vencida
                          ? Colors.red.shade600
                          : Colors.blue.shade600)),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.5,
            children: [
              _tarjetaAhorro(
                  'Diario', desglose.ahorrosDiarios, Icons.calendar_today),
              _tarjetaAhorro(
                  'Semanal', desglose.ahorrosSemanal, Icons.date_range),
              _tarjetaAhorro(
                  'Quincenal', desglose.ahorrosQuincenal, Icons.event_note),
              _tarjetaAhorro(
                  'Mensual', desglose.ahorrosMensual, Icons.calendar_month),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300)),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                      '💡 Recomendado: ${_nombrePeriodo(desglose.periodoRecomendado)}',
                      style: TextStyle(color: Colors.green.shade700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaAhorro(String periodo, double monto, IconData icono) {
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
          FittedBox(
            // ← Evita desbordamiento con montos grandes
            fit: BoxFit.scaleDown,
            child: Text(
              UIHelpers.formatCurrency(monto),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _nombrePeriodo(String p) => switch (p) {
        'diario' => 'Ahorrar diariamente',
        'semanal' => 'Ahorrar semanalmente',
        'quincenal' => 'Ahorrar quincenalmente',
        'mensual' => 'Ahorrar mensualmente',
        _ => 'Período personalizado',
      };

  Widget _tarjetaMetaInvalida(BuildContext context, String msg) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text(meta.nombre,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Text('⚠️ $msg', style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onEliminar),
        ]),
      ),
    );
  }
}
