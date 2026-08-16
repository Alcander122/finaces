// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/portafolio_model.dart';
import '../models/asset_catalog_model.dart';
import '../repositories/asset_catalog_repository.dart';
import '../services/portafolio_service.dart';
import '../services/currency_service.dart';
import 'investment_provider.dart';

final portafolioServiceProvider = Provider((ref) => PortafolioService());

final assetCatalogRepositoryProvider = Provider<AssetCatalogRepository>((ref) {
  return AssetCatalogRepository();
});

final assetCatalogProvider = FutureProvider<List<AssetCatalogModel>>((ref) {
  return ref.watch(assetCatalogRepositoryProvider).getCatalog();
});

final portafoliosProvider =
    StreamProvider.autoDispose.family<List<Portafolio>, String>((ref, userId) {
  if (userId.isEmpty) {
    return Stream.value([]);
  }
  return ref
      .watch(portafolioServiceProvider)
      .obtenerPortafoliosEnTiempoReal(userId);
});

/// Proveedor para las tasas de conversión de divisas en tiempo real (COP, USD, EUR)
final exchangeRatesProvider = FutureProvider<Map<String, double>>((ref) async {
  final service = ref.watch(currencyServiceProvider);
  try {
    final usdToCop = await service.getExchangeRate('USD', 'COP');
    final eurToCop = await service.getExchangeRate('EUR', 'COP');
    return {
      'USD': usdToCop,
      'EUR': eurToCop,
      'COP': 1.0,
    };
  } catch (e) {
    // Si falla la petición, retornamos tasas estables de respaldo
    return {
      'USD': 4000.0,
      'EUR': 4300.0,
      'COP': 1.0,
    };
  }
});

/// Representación del estado consolidado del portafolio en la capa de negocio
class PortfolioDashboardState {
  final double totalPortfolioValueCOP;
  final List<PortafolioItemState> portfolioItems;
  final Map<String, double> categoryDistribution; // e.g. {'Criptomonedas': 5000000.0, 'Acciones': 12000000.0}
  final int numberOfAssets;

  PortfolioDashboardState({
    required this.totalPortfolioValueCOP,
    required this.portfolioItems,
    required this.categoryDistribution,
    required this.numberOfAssets,
  });
}

/// Estado individual para cada portafolio en la lista principal
class PortafolioItemState {
  final Portafolio portafolio;
  final double totalValueCOP;

  PortafolioItemState({
    required this.portafolio,
    required this.totalValueCOP,
  });
}

/// Provider unificado que actúa como ÚNICA FUENTE DE VERDAD para el tablero de portafolio.
/// Combina portafolios, inversiones y tipos de cambio, eliminando cálculos de la UI.
final portfolioDashboardProvider = Provider.autoDispose.family<AsyncValue<PortfolioDashboardState>, String>((ref, userId) {
  if (userId.isEmpty) {
    return AsyncValue.data(PortfolioDashboardState(
      totalPortfolioValueCOP: 0.0,
      portfolioItems: [],
      categoryDistribution: {},
      numberOfAssets: 0,
    ));
  }
  final portafoliosAsync = ref.watch(portafoliosProvider(userId));
  final allInvestmentsAsync = ref.watch(allInvestmentsProvider(userId));
  final ratesAsync = ref.watch(exchangeRatesProvider);

  return portafoliosAsync.when(
    data: (portfolios) => allInvestmentsAsync.when(
      data: (investments) {
        // Obtenemos tasas o usamos fallback síncrono si el FutureProvider no ha resuelto aún
        final rates = ratesAsync.value ?? {
          'USD': 4000.0,
          'EUR': 4300.0,
          'COP': 1.0,
        };

        double totalValueCOP = 0.0;
        final List<PortafolioItemState> items = [];
        final Map<String, double> categoryDist = {};
        int activeAssets = 0;

        // 1. Agrupar inversiones por portafolio e invertir de forma correcta convirtiendo divisas
        for (final portfolio in portfolios) {
          double portfolioTotalCOP = 0.0;
          
          final portfolioInvestments = investments.where((inv) => inv.portafolioId == portfolio.id);
          for (final inv in portfolioInvestments) {
            final rate = rates[inv.moneda.toUpperCase()] ?? 1.0;
            final invValueCOP = inv.invMensual * rate;
            
            portfolioTotalCOP += invValueCOP;

            // Agrupar por categoría de activo para la distribución
            final category = inv.activo.isEmpty ? 'Otros' : inv.activo;
            categoryDist[category] = (categoryDist[category] ?? 0.0) + invValueCOP;
            activeAssets++;
          }

          items.add(PortafolioItemState(
            portafolio: portfolio,
            totalValueCOP: portfolioTotalCOP,
          ));

          totalValueCOP += portfolioTotalCOP;
        }

        return AsyncValue.data(PortfolioDashboardState(
          totalPortfolioValueCOP: totalValueCOP,
          portfolioItems: items,
          categoryDistribution: categoryDist,
          numberOfAssets: activeAssets,
        ));
      },
      loading: () => const AsyncValue.loading(),
      error: (err, stack) => AsyncValue.error(err, stack),
    ),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

