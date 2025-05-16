// category_summary_provider.dart

import 'dart:async';
import 'package:async/async.dart';
import 'package:finances/core/data/models/filter.dart';
import 'package:finances/core/data/models/egreso_model.dart';
import 'package:finances/core/data/models/ingreso.model.dart';
import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/providers/filter_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ingresosEgresosCategoryStreamProvider = StreamProvider<Map<String, Map<String, double>>>((ref) {
  final filter = ref.watch(filterProvider);

  final ingresosStream = _getCategoryDataStream(
    isExpense: false,
    ref: ref,
  );

  final egresosStream = _getCategoryDataStream(
    isExpense: true,
    ref: ref,
  );

  return StreamZip([
    ingresosStream,
    egresosStream,
  ]).map((values) => {
        'ingresos': values[0],
        'egresos': values[1],
      });
});

Stream<Map<String, double>> _getCategoryDataStream({
  required bool isExpense,
  required Ref ref,
}) {
  final controller = StreamController<Map<String, double>>();
  late Timer timer;

  void tick() async {
    if (controller.isClosed) return;

    Map<String, double> categoryData = {};

    final List<dynamic> data = isExpense
        ? ref.read(egresosFiltradosProvider).value ?? []
        : ref.read(ingresosFiltradosProvider).value ?? [];

    for (var item in data) {
      if (isExpense) {
        final egreso = item as Egreso;
        categoryData.update(
          egreso.categoria,
          (value) => value + egreso.valor,
          ifAbsent: () => egreso.valor.toDouble(),
        );
      } else {
        final ingreso = item as Ingreso;
        categoryData.update(
          ingreso.categoria,
          (value) => value + ingreso.valor,
          ifAbsent: () => ingreso.valor.toDouble(),
        );
      }
    }

    controller.add(categoryData);
    timer = Timer(const Duration(seconds: 1), tick);
  }

  timer = Timer(const Duration(milliseconds: 0), tick);

  controller.onCancel = () {
    timer.cancel();
  };

  return controller.stream;
}