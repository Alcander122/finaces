import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:finances/core/data/providers/ingreso_provider.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/presentations/screens/Pagos/models/payment.dart';
import 'package:finances/presentations/screens/Pagos/models/payment_enums.dart';
import 'package:finances/presentations/screens/Pagos/providers/payment_providers.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/theme/theme.dart';
import 'package:finances/presentations/theme/themes.dart';

/// Tarjeta responsiva de estadísticas financieras avanzadas que valida:
/// - Egresos ya ejecutados
/// - Pagos Pendientes (únicos por vencer)
/// - Pagos Programados (recurrentes del periodo)
/// - Saldo Realmente Disponible y Nivel de Compromiso
class PaymentCommitmentCard extends ConsumerWidget {
  const PaymentCommitmentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.uid ?? '';
    final filter = ref.watch(filterProvider);

    final ingresosAsync = ref.watch(filteredIngresosProvider);
    final egresosAsync = ref.watch(filteredEgresosProvider);
    final paymentsAsync = ref.watch(paymentsStreamProvider(userId));

    final totalIngresos = ingresosAsync.maybeWhen(
      data: (value) => value,
      orElse: () => 0.0,
    );

    final totalEgresos = egresosAsync.maybeWhen(
      data: (value) => value,
      orElse: () => 0.0,
    );

    final now = DateTime.now();
    final effectiveStartDate =
        filter.startDate ?? DateTime(now.year, now.month, 1);
    final effectiveEndDate =
        filter.endDate ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return paymentsAsync.maybeWhen(
      data: (payments) => _buildCard(
        context,
        payments,
        totalIngresos,
        totalEgresos,
        effectiveStartDate,
        effectiveEndDate,
      ),
      loading: () => _buildLoadingCard(context),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.colors.surfaceContainerHigh
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDarkMode ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: const Center(child: CircularProgressIndicator.adaptive()),
    );
  }

  Widget _buildCard(
    BuildContext context,
    List<Payment> payments,
    double totalIngresos,
    double totalEgresos,
    DateTime startDate,
    DateTime endDate,
  ) {
    final isDark = context.isDarkMode;

    // 1. Filtrar pagos en el rango del periodo actual
    double pendientesPorPagar = 0.0;
    int pendientesCount = 0;

    double programadosPorPagar = 0.0;
    int programadosCount = 0;

    for (final p in payments) {
      final due = p.nextDueDate;
      if (due == null) continue;

      final dueUtc = DateTime(due.year, due.month, due.day);
      final startUtc = DateTime(startDate.year, startDate.month, startDate.day);
      final endUtc = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      // Comprobar si el vencimiento entra en el periodo
      final isInPeriod = (dueUtc.isAfter(startUtc) || dueUtc.isAtSameMomentAs(startUtc)) &&
          (dueUtc.isBefore(endUtc) || dueUtc.isAtSameMomentAs(endUtc));

      if (p.status == PaymentStatus.pending && isInPeriod) {
        if (p.recurrence.unit == FrequencyUnit.none) {
          // Pago pendiente único
          pendientesPorPagar += p.totalAmount;
          pendientesCount++;
        } else {
          // Pago programado / recurrente
          programadosPorPagar += p.totalAmount;
          programadosCount++;
        }
      }
    }

    // 2. Cálculos de Compromiso y Saldo Real
    final totalCompromisosPorPagar = pendientesPorPagar + programadosPorPagar;
    final saldoContableHoy = totalIngresos - totalEgresos;
    final saldoRealDisponible = saldoContableHoy - totalCompromisosPorPagar;

    final porcentajeCompromiso = totalIngresos > 0
        ? ((totalCompromisosPorPagar / totalIngresos) * 100).clamp(0, 100).toDouble()
        : 0.0;

    final porcentajeEgresos = totalIngresos > 0
        ? ((totalEgresos / totalIngresos) * 100).clamp(0, 100).toDouble()
        : 0.0;

    final porcentajeLibre = totalIngresos > 0
        ? ((saldoRealDisponible / totalIngresos) * 100).clamp(0, 100).toDouble()
        : 0.0;

    // Estado de Salud
    final bool saldoNegativo = saldoRealDisponible < 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? context.colors.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con Título y Badge de Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Themes.primary.withValues(alpha: isDark ? 0.25 : 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: isDark ? Themes.degradientLight : Themes.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AutoSizeText(
                          'Saldo Real Disponible',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          minFontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (saldoNegativo
                            ? Colors.red
                            : (porcentajeCompromiso > 60 ? Colors.amber : Colors.green))
                        .withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AutoSizeText(
                    saldoNegativo
                        ? 'Déficit Proyectado'
                        : (porcentajeCompromiso > 60 ? 'Alto Compromiso' : 'Saludable'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: saldoNegativo
                          ? Colors.redAccent
                          : (porcentajeCompromiso > 60
                              ? Colors.amber.shade700
                              : Colors.green.shade600),
                    ),
                    maxLines: 1,
                    minFontSize: 9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Saldo Real Destacado
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: AutoSizeText(
                        UIHelpers.formatCurrency(saldoRealDisponible),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: saldoNegativo
                              ? Colors.redAccent
                              : (isDark ? Colors.white : Themes.primary),
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        minFontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'tras pagar compromisos',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Barra visual de Distribución del Ingreso
            if (totalIngresos > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      if (porcentajeEgresos > 0)
                        Expanded(
                          flex: (porcentajeEgresos * 10).toInt().clamp(1, 1000),
                          child: Container(color: Colors.redAccent),
                        ),
                      if (porcentajeCompromiso > 0)
                        Expanded(
                          flex: (porcentajeCompromiso * 10).toInt().clamp(1, 1000),
                          child: Container(color: Colors.amber.shade700),
                        ),
                      if (porcentajeLibre > 0)
                        Expanded(
                          flex: (porcentajeLibre * 10).toInt().clamp(1, 1000),
                          child: Container(color: Colors.greenAccent.shade700),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Leyenda de la barra
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _buildLegendDot(Colors.redAccent, 'Egresos (${porcentajeEgresos.toStringAsFixed(0)}%)', isDark),
                  _buildLegendDot(Colors.amber.shade700, 'Pagos por vencer (${porcentajeCompromiso.toStringAsFixed(0)}%)', isDark),
                  if (porcentajeLibre > 0)
                    _buildLegendDot(Colors.greenAccent.shade700, 'Libre (${porcentajeLibre.toStringAsFixed(0)}%)', isDark),
                ],
              ),
              const SizedBox(height: 16),
            ],

            const Divider(height: 1),
            const SizedBox(height: 12),

            // Desglose de Compromisos en Grid Responsivo
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 320;
                return isNarrow
                    ? Column(
                        children: [
                          _buildDetailItem(
                            context,
                            icon: Icons.access_time_filled,
                            color: Colors.orange,
                            label: 'Pagos Pendientes (Únicos)',
                            count: '$pendientesCount por pagar',
                            amount: UIHelpers.formatCurrency(pendientesPorPagar),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailItem(
                            context,
                            icon: Icons.calendar_month,
                            color: Colors.blue,
                            label: 'Pagos Programados (Fijos)',
                            count: '$programadosCount recurrentes',
                            amount: UIHelpers.formatCurrency(programadosPorPagar),
                            isDark: isDark,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              context,
                              icon: Icons.access_time_filled,
                              color: Colors.orange,
                              label: 'Pagos Pendientes',
                              count: '$pendientesCount únicos',
                              amount: UIHelpers.formatCurrency(pendientesPorPagar),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDetailItem(
                              context,
                              icon: Icons.calendar_month,
                              color: Colors.blue,
                              label: 'Pagos Programados',
                              count: '$programadosCount fijos',
                              amount: UIHelpers.formatCurrency(programadosPorPagar),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String count,
    required String amount,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 1,
                  minFontSize: 9,
                  overflow: TextOverflow.ellipsis,
                ),
                AutoSizeText(
                  count,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  minFontSize: 8,
                ),
                const SizedBox(height: 2),
                AutoSizeText(
                  amount,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  minFontSize: 9,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
