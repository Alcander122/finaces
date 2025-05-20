import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:flutter/material.dart';
import 'package:finances/core/data/models/filter.dart';
import 'package:finances/presentations/widgets/app_bar_finances.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CategoryDetailsScreen extends ConsumerWidget {
  final String category;
  final Filter filter;
  final bool isExpense;

  const CategoryDetailsScreen({
    super.key,
    required this.category,
    required this.filter,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<List<Ingreso>>? ingresosAsync;
    AsyncValue<List<Egreso>>? egresosAsync;

    if (isExpense) {
      egresosAsync = ref.watch(egresosPorCategoriaProvider(category));
    } else {
      ingresosAsync = ref.watch(ingresosPorCategoriaProvider(category));
    }

    return Scaffold(
      appBar: AppBarFinances(
        title: 'Detalles de $category',
        showBackButton: true,
        showProfileAction: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isExpense
            ? _buildExpenseDetails(egresosAsync!)
            : _buildIncomeDetails(ingresosAsync!),
      ),
    );
  }

  Widget _buildIncomeDetails(AsyncValue<List<Ingreso>> ingresosAsync) {
    return ingresosAsync.when(
      data: (ingresos) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total: \$${ingresos.fold(0.0, (sum, i) => sum + i.valor).toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...ingresos.map((ingreso) => Card(
            elevation: 2,
            child: ListTile(
              title: Text(ingreso.concepto),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(ingreso.fecha)),
              trailing: Text('\$${ingreso.valor.toStringAsFixed(2)}'),
            ),
          )),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Error: $error'),
    );
  }

  Widget _buildExpenseDetails(AsyncValue<List<Egreso>> egresosAsync) {
    return egresosAsync.when(
      data: (egresos) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total: \$${egresos.fold(0.0, (sum, e) => sum + e.valor).toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...egresos.map((egreso) => Card(
            elevation: 2,
            child: ListTile(
              title: Text(egreso.descripcion),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(egreso.fecha)),
              trailing: Text('\$${egreso.valor.toStringAsFixed(2)}'),
            ),
          )),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Error: $error'),
    );
  }
}