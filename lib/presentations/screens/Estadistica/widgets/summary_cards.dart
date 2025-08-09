import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart'; // 📦 Para ajustar tamaño de texto automáticamente

import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/providers/ingreso_provider.dart';

/// Widget que muestra tarjetas con el resumen de ingresos, gastos y balance
class SummaryCards extends ConsumerWidget {
  const SummaryCards({super.key});

  /// Función para formatear un número a pesos colombianos sin decimales
  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO', // Configuración regional Colombia
      symbol: '\$', // Símbolo de pesos
      decimalDigits: 0, // Sin decimales
    );
    return formatter
        .format(value)
        .replaceAll(' ', '\u00A0'); // Espacio no separable
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          // Tarjeta de INGRESOS
          _buildCard(
            title: 'Ingresos',
            value: ref.watch(filteredIngresosProvider),
            icon: Icons.trending_up,
            valueColor: Colors.green,
          ),
          const SizedBox(width: 8),

          // Tarjeta de GASTOS
          _buildCard(
            title: 'Gastos',
            value: ref.watch(filteredTotalGastosProvider),
            icon: Icons.trending_down,
            valueColor: Colors.red,
          ),
          const SizedBox(width: 8),

          // Tarjeta de BALANCE
          _buildBalanceCard(ref),
        ],
      ),
    );
  }

  /// Construye cada tarjeta con título, ícono y valor
  Widget _buildCard({
    required String title,
    required AsyncValue<double> value,
    required IconData icon,
    required Color valueColor,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono principal
              Icon(icon, color: valueColor, size: 28),
              const SizedBox(height: 6),

              // Título
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),

              // Monto o indicador de carga/error
              value.when(
                data: (data) => AutoSizeText(
                  formatCurrency(data), // Formatear valor
                  maxLines: 1, // Solo una línea
                  minFontSize: 10, // Tamaño mínimo permitido
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20, // Tamaño base
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
                loading: () => const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (err, _) => const Text('Error'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta especial para mostrar el balance (ingresos - gastos)
  Widget _buildBalanceCard(WidgetRef ref) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono
              const Icon(Icons.account_balance_wallet,
                  color: Colors.blue, size: 28),
              const SizedBox(height: 6),

              // Título
              const Text(
                'Balance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),

              // Cálculo de balance (ingresos - gastos)
              ref.watch(filteredIngresosProvider).when(
                    data: (ing) => ref.watch(filteredTotalGastosProvider).when(
                          data: (gas) => AutoSizeText(
                            formatCurrency(ing - gas),
                            maxLines: 1,
                            minFontSize: 10,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          loading: () => const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (err, _) => const Text('Error'),
                        ),
                    loading: () => const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (err, _) => const Text('Error'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
