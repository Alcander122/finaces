// lib/core/providers/investment_provider.dart
import 'package:finances/core/data/models/investment_model.dart';
import 'package:finances/core/data/services/investment_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

/// Proveedor del servicio de inversiones
final investmentServiceProvider = Provider((ref) => InvestmentService());

/// StreamProvider: inversiones de un portafolio en tiempo real
final investmentsProvider =
    StreamProvider.family<List<Investment>, Tuple2<String, String>>(
  (ref, params) {
    final userId = params.item1;
    final portafolioId = params.item2;
    return ref
        .watch(investmentServiceProvider)
        .obtenerInversionesEnTiempoReal(userId, portafolioId);
  },
);

/// StreamProvider: todas las inversiones del usuario
final allInvestmentsProvider = StreamProvider.family<List<Investment>, String>(
  (ref, userId) {
    return ref.watch(investmentServiceProvider).obtenerTodosInvestments(userId);
  },
);
