import 'package:finances/core/data/models/filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/providers/ingreso_provider.dart';
import 'package:intl/intl.dart';

// Clase para mostrar las tarjetas resumen de ingresos, gastos y balance
class SummaryCards extends ConsumerWidget {
  // Filtro seleccionado (mensual, trimestral, anual o personalizado)
  final FilterType filter;
  // Rango de fechas seleccionado (si el filtro es personalizado)
  final DateTimeRange? dateRange;

  // Constructor de la clase
  const SummaryCards({
    super.key,
    required this.filter,
    this.dateRange,
  });

  // Método para formatear los valores monetarios con decimales y separadores de miles
  String formatCurrency(double value) {
    // Utilizamos NumberFormat para dar formato al valor según el patrón de Colombia
    final formatter = NumberFormat.decimalPattern('es_CO');
    // Devolvemos el valor formateado con un símbolo de dólar al inicio
    return '\$${formatter.format(value)}';
  }

  // Método principal de construcción del widget
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Agregamos padding horizontal a la fila de tarjetas
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      // Creamos una fila para mostrar las tres tarjetas
      child: Row(
        mainAxisAlignment: MainAxisAlignment
            .spaceEvenly, // Distribuimos las tarjetas equitativamente
        children: [
          // Tarjeta de ingresos
          _buildIngresosCard(context, ref),
          // Tarjeta de gastos
          _buildGastosCard(context, ref),
          // Tarjeta de balance
          _buildBalanceCard(context, ref),
        ],
      ),
    );
  }

  // Método para construir la tarjeta de ingresos
  Widget _buildIngresosCard(BuildContext context, WidgetRef ref) {
    // Utilizamos el proveedor filteredIngresosProvider para obtener los ingresos filtrados
    return ref.watch(filteredIngresosProvider).when(
          // Si hay datos, construimos la tarjeta con el valor
          data: (data) {
            // Usamos formatCurrency para dar formato al valor de ingresos
            return _buildSummaryCard(
              context,
              title: 'Ingresos',
              value: formatCurrency(data),
              icon: Icons.arrow_upward,
              color: Colors.green,
            );
          },
          // Si están cargando, mostramos un indicador de carga
          loading: () => const CircularProgressIndicator(),
          // Si hay un error, mostramos un texto de error
          error: (error, stackTrace) => Text('Error: $error'),
        );
  }

  // Método para construir la tarjeta de gastos
  Widget _buildGastosCard(BuildContext context, WidgetRef ref) {
    // Utilizamos el proveedor totalGastosProvider para obtener los gastos totales
    return ref.watch(totalGastosProvider).when(
          // Si hay datos, construimos la tarjeta con el valor
          data: (data) {
            // Usamos formatCurrency para dar formato al valor de gastos
            return _buildSummaryCard(
              context,
              title: 'Gastos',
              value: formatCurrency(data),
              icon: Icons.arrow_downward,
              color: Colors.red,
            );
          },
          // Si están cargando, mostramos un indicador de carga
          loading: () => const CircularProgressIndicator(),
          // Si hay un error, mostramos un texto de error
          error: (error, stackTrace) => Text('Error: $error'),
        );
  }

  // Método para construir la tarjeta de balance
  Widget _buildBalanceCard(BuildContext context, WidgetRef ref) {
    // Utilizamos el proveedor filteredIngresosProvider para obtener los ingresos filtrados
    return ref.watch(filteredIngresosProvider).when(
          // Si hay datos de ingresos, continuamos
          data: (ingresos) {
            // Luego, utilizamos el proveedor totalGastosProvider para obtener los gastos totales
            return ref.watch(totalGastosProvider).when(
                  // Si hay datos de gastos, calculamos el balance
                  data: (gastos) {
                    double balance = ingresos - gastos; // Calculamos el balance
                    // Determinamos el color del balance (azul para positivo, rojo para negativo)
                    Color balanceColor =
                        balance >= 0 ? Colors.blue : Colors.red;

                    // Usamos formatCurrency para dar formato al valor del balance
                    return _buildSummaryCard(
                      context,
                      title: 'Balance',
                      value: formatCurrency(balance),
                      icon: Icons.trending_up,
                      color: balanceColor,
                    );
                  },
                  // Si están cargando los gastos, mostramos un indicador de carga
                  loading: () => const CircularProgressIndicator(),
                  // Si hay un error en los gastos, mostramos un texto de error
                  error: (error, stackTrace) => Text('Error: $error'),
                );
          },
          // Si están cargando los ingresos, mostramos un indicador de carga
          loading: () => const CircularProgressIndicator(),
          // Si hay un error en los ingresos, mostramos un texto de error
          error: (error, stackTrace) => Text('Error: $error'),
        );
  }

  // Método para construir una tarjeta resumen genérica
  Widget _buildSummaryCard(
    BuildContext context, {
    required String title, // Título de la tarjeta (ej: "Ingresos")
    required String value, // Valor formateado (ej: "\$1.234.567,89")
    required IconData icon, // Ícono de la tarjeta
    required Color color, // Color de la tarjeta
  }) {
    // Devolvemos una tarjeta con elevación y bordes redondeados
    return Card(
      elevation: 4, // Elevación de la tarjeta
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Bordes redondeados
      ),
      // Contenido de la tarjeta
      child: Container(
        padding: const EdgeInsets.all(15), // Padding interno
        // Decoración con degradado de colores
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.2), // Color superior más transparente
              color.withValues(alpha: 0.1) // Color inferior más transparente
            ],
            begin: Alignment.topCenter, // Comienzo del degradado
            end: Alignment.bottomCenter, // Fin del degradado
          ),
        ),
        // Contenido de la tarjeta
        child: Column(
          children: [
            Icon(icon, color: color, size: 20), // Ícono de la tarjeta
            const SizedBox(height: 5), // Espacio entre ícono y título
            Text(title, style: const TextStyle(fontSize: 14)), // Título
            const SizedBox(height: 5), // Espacio entre título y valor
            Text(
              value, // Valor formateado
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
