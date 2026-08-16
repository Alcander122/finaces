// lib/core/providers/investment_provider.dart
import 'package:finances/core/data/models/investment_model.dart';
import 'package:finances/core/data/services/investment_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';
import 'portafolio_provider.dart';

/// Proveedor del servicio de inversiones
final investmentServiceProvider = Provider((ref) => InvestmentService());

/// StreamProvider: inversiones de un portafolio en tiempo real
final investmentsProvider =
    StreamProvider.autoDispose.family<List<Investment>, Tuple2<String, String>>(
  (ref, params) {
    final userId = params.item1;
    final portafolioId = params.item2;
    if (userId.isEmpty || portafolioId.isEmpty) {
      return Stream.value([]);
    }
    return ref
        .watch(investmentServiceProvider)
        .obtenerInversionesEnTiempoReal(userId, portafolioId);
  },
);

/// StreamProvider: todas las inversiones del usuario
final allInvestmentsProvider = StreamProvider.autoDispose.family<List<Investment>, String>(
  (ref, userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }
    return ref.watch(investmentServiceProvider).obtenerTodosInvestments(userId);
  },
);

/// Representación con conversión de divisa síncrona de una inversión individual
class InvestmentItemState {
  final Investment investment;
  final double convertedValueCOP;

  InvestmentItemState({
    required this.investment,
    required this.convertedValueCOP,
  });
}

/// Provider unificado para el detalle de un portafolio.
/// Combina las inversiones y las tasas de cambio de divisas reactivas.
final portfolioDetailProvider = Provider.autoDispose.family<AsyncValue<List<InvestmentItemState>>, Tuple2<String, String>>((ref, params) {
  final userId = params.item1;
  final portafolioId = params.item2;

  final investmentsAsync = ref.watch(investmentsProvider(Tuple2(userId, portafolioId)));
  final ratesAsync = ref.watch(exchangeRatesProvider);

  return investmentsAsync.when(
    data: (investments) {
      final rates = ratesAsync.value ?? {
        'USD': 4000.0,
        'EUR': 4300.0,
        'COP': 1.0,
      };

      final items = investments.map((inv) {
        final rate = rates[inv.moneda.toUpperCase()] ?? 1.0;
        return InvestmentItemState(
          investment: inv,
          convertedValueCOP: inv.invMensual * rate,
        );
      }).toList();

      return AsyncValue.data(items);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

