// category_summary_provider.dart
import 'package:finances/core/data/models/filter.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

/// Proveedor principal que combina ingresos y egresos filtrados por categoría
final ingresosEgresosCategoryStreamProvider = StreamProvider<Map<String, Map<String, double>>>((ref) {
  final ingresosStream = ref.watch(ingresosFiltradosProvider.stream);
  final egresosStream = ref.watch(egresosFiltradosProvider.stream);

  // Usa Rx.combineLatest2 de rxdart
  return Rx.combineLatest2(
    ingresosStream,
    egresosStream,
    (List<Ingreso> ingresos, List<Egreso> egresos) {
      return {
        'ingresos': _groupByCategory(ingresos, false),
        'egresos': _groupByCategory(egresos, true),
      };
    },
  );
});

/// Función auxiliar para agrupar transacciones por categoría
Map<String, double> _groupByCategory(List<dynamic> transactions, bool isExpense) {
  final categoryMap = <String, double>{};

  for (final transaction in transactions) {
    // Extraer datos según el tipo de transacción
    final String category;
    final double amount;
    
    if (isExpense) {
      final egreso = transaction as Egreso;
      category = egreso.categoria;
      amount = egreso.valor.toDouble();
    } else {
      final ingreso = transaction as Ingreso;
      category = ingreso.categoria;
      amount = ingreso.valor.toDouble();
    }

    // Actualizar sumatorio por categoría
    categoryMap.update(
      category,
      (existing) => existing + amount,
      ifAbsent: () => amount,
    );
  }
  
  return categoryMap;
}