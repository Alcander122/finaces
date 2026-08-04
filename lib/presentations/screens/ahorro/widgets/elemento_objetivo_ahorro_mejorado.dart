// 🎨 presentations/screens/ahorro/elemento_objetivo_ahorro_mejorado.dart
// ============================================================================
// WIDGET: Tarjeta de meta de ahorro premium estilo Fintech (M3, animada y responsiva)
// ============================================================================

import 'package:finances/core/data/models/objetivo_ahorro.dart';
import 'package:finances/core/data/utils/ahorro_calculator.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      return _tarjetaMetaInvalida(context, 'Monto objetivo inválido');
    }

    // Cálculo considerando lo ya ahorrado
    late final AhorroDesglose desglose;
    try {
      desglose = AhorroCalculator.calcularDesglose(
        montoObjetivo: meta.montoObjetivo,
        fechaObjetivo: meta.fechaObjetivo,
        montoActual: meta.montoActual, // solo lo pendiente
      );
    } catch (e) {
      desglose = AhorroDesglose.invalido(
        montoObjetivo: meta.montoObjetivo,
        fechaInicio: ahora,
        fechaObjetivo: meta.fechaObjetivo,
      );
    }

    // Colores temáticos dinámicos según el estado del progreso y vencimiento
    Color getProgressColor() {
      if (estaVencida && meta.progreso < 100) return Themes.red;
      if (meta.progreso >= 100) return Colors.green.shade600;
      if (meta.progreso > 50) return Colors.green.shade500;
      return Colors.amber.shade600;
    }

    final double progresoVal = (meta.progreso / 100).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.isDarkMode ? Colors.white12 : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fila Superior: Nombre de la Meta y Fecha Objetivo
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.nombre,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.isDarkMode ? context.colors.onSurface : Themes.primary,
                              fontSize: 18,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Finaliza: ${DateFormat('dd/MM/yyyy').format(meta.fechaObjetivo)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Porcentaje como insignia destacada
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: getProgressColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${meta.progreso.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: getProgressColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notificación de meta vencida si aplica
            if (estaVencida && meta.progreso < 100)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_off_outlined, color: Themes.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta meta ha superado su fecha límite.',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Barra de progreso animada de M3
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progresoVal),
              duration: const Duration(milliseconds: 800),
              curve: Curves.fastOutSlowIn,
              builder: (context, value, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 14,
                    color: getProgressColor(),
                    backgroundColor: Colors.grey.shade100,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Layout Responsivo para Montos
            LayoutBuilder(
              builder: (context, constraints) {
                final bool esAncho = constraints.maxWidth > 300;
                final widgetMontoActual = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ahorrado',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        UIHelpers.formatCurrency(meta.montoActual),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                );

                final widgetMontoObjetivo = Column(
                  crossAxisAlignment: esAncho ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Objetivo: ${UIHelpers.formatCurrency(meta.montoObjetivo)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta.montoRestante > 0
                          ? 'Faltan ${UIHelpers.formatCurrency(meta.montoRestante)}'
                          : '🎉 ¡Meta cumplida!',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: meta.montoRestante > 0 ? Colors.grey.shade500 : Colors.green,
                      ),
                    ),
                  ],
                );

                if (esAncho) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: widgetMontoActual),
                      const SizedBox(width: 12),
                      Expanded(child: widgetMontoObjetivo),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widgetMontoActual,
                      const SizedBox(height: 12),
                      widgetMontoObjetivo,
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            // Plan de Ahorro Desglosado Responsivo
            if (mostrarDesglose && desglose.esValido && meta.montoRestante > 0)
              _construirSeccionDesglose(
                  context, desglose, estaVencida, meta.montoActual > 0)
            else if (mostrarDesglose && meta.montoRestante > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  estaVencida
                      ? 'El plan de ahorro ya expiró.'
                      : 'El plan de ahorro no está disponible.',
                  style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),

            if (mostrarDesglose && meta.montoRestante > 0)
              const SizedBox(height: 20),

            // Fila de Botones M3
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Detalles / Historial
                _botonAccion(
                  icon: Icons.history,
                  tooltip: 'Historial',
                  color: Themes.primary,
                  onPressed: onVerDetalles,
                ),
                const SizedBox(width: 8),
                
                // Eliminar
                _botonAccion(
                  icon: Icons.delete_outline,
                  tooltip: 'Eliminar',
                  color: Colors.red.shade400,
                  onPressed: onEliminar,
                ),
                
                const Spacer(),

                // Transacciones si no está vencida y no completada
                if (!estaVencida && meta.montoRestante > 0) ...[
                  // Retirar
                  OutlinedButton.icon(
                    onPressed: meta.montoActual > 0 ? () => onTransaccion('retiro') : null,
                    icon: const Icon(Icons.remove, size: 16),
                    label: const Text(
                      'Retirar',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Depositar
                  ElevatedButton.icon(
                    onPressed: () => onTransaccion('deposito'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Ahorrar',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode ? context.colors.surfaceContainerHigh : Themes.infoBlue.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.isDarkMode ? Colors.white12 : Themes.primary.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: context.colors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tieneProgreso ? 'Plan de ahorro restante' : 'Plan de ahorro sugerido',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: context.isDarkMode ? context.colors.onSurface : Themes.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Themes.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  desglose.mensajeTiempoRestante,
                  style: const TextStyle(
                    color: Themes.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cuadrícula adaptable responsiva (Evita overflows de altura)
          LayoutBuilder(
            builder: (context, constraints) {
              final bool esAncho = constraints.maxWidth > 345;
              if (esAncho) {
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.1,
                  children: [
                    _tarjetaAhorro(context, 'Diario', desglose.ahorrosDiarios, Icons.calendar_today, Colors.blue.shade50),
                    _tarjetaAhorro(context, 'Semanal', desglose.ahorrosSemanal, Icons.date_range, Colors.indigo.shade50),
                    _tarjetaAhorro(context, 'Quincenal', desglose.ahorrosQuincenal, Icons.event_note, Colors.teal.shade50),
                    _tarjetaAhorro(context, 'Mensual', desglose.ahorrosMensual, Icons.calendar_month, Colors.purple.shade50),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _tarjetaAhorro(context, 'Diario', desglose.ahorrosDiarios, Icons.calendar_today, Colors.blue.shade50),
                    const SizedBox(height: 8),
                    _tarjetaAhorro(context, 'Semanal', desglose.ahorrosSemanal, Icons.date_range, Colors.indigo.shade50),
                    const SizedBox(height: 8),
                    _tarjetaAhorro(context, 'Quincenal', desglose.ahorrosQuincenal, Icons.event_note, Colors.teal.shade50),
                    const SizedBox(height: 8),
                    _tarjetaAhorro(context, 'Mensual', desglose.ahorrosMensual, Icons.calendar_month, Colors.purple.shade50),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 12),

          // Banner de Insight Financiero Inteligente
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: context.isDarkMode
                    ? [const Color(0xFF064E3B), const Color(0xFF047857)]
                    : [Colors.green.shade50, Colors.teal.shade50.withOpacity(0.4)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.isDarkMode ? Colors.green.shade700 : Colors.green.shade100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? Colors.green.shade900 : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.star, color: context.isDarkMode ? Colors.green.shade300 : Colors.green.shade700, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECOMENDACIÓN DE AHORRO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: context.isDarkMode ? Colors.green.shade200 : Colors.green.shade900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _nombrePeriodo(desglose.periodoRecomendado),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.isDarkMode ? Colors.white : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaAhorro(BuildContext context, String periodo, double monto, IconData icono, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.isDarkMode ? context.colors.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.isDarkMode ? Colors.white12 : Themes.primary.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.isDarkMode ? context.colors.primary.withValues(alpha: 0.15) : bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 16, color: context.isDarkMode ? context.colors.primary : Themes.primary.withOpacity(0.8)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  periodo,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.isDarkMode ? context.colors.onSurfaceVariant : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    UIHelpers.formatCurrency(monto),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.isDarkMode ? context.colors.onSurface : Themes.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonAccion({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Text(
            meta.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Text(msg, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          _botonAccion(
            icon: Icons.delete_outline,
            tooltip: 'Eliminar',
            color: Colors.red,
            onPressed: onEliminar,
          ),
        ],
      ),
    );
  }
}
