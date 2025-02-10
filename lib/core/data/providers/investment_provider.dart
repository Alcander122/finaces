import 'package:finances/core/data/models/investment_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';
import '../services/investment_service.dart';

final investmentServiceProvider = Provider((ref) => InvestmentService());

final investmentsProvider =
    StreamProvider.family<List<Investment>, Tuple2<String, String>>(
        (ref, params) {
  final userId = params.item1;
  final portafolioId = params.item2;
  return ref
      .watch(investmentServiceProvider)
      .obtenerInvestments(userId, portafolioId);
});

final allInvestmentsProvider =
    StreamProvider.family<List<Investment>, String>((ref, userId) {
  return ref.watch(investmentServiceProvider).obtenerTodosInvestments(userId);
});
