import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';

/// Provider local para controlar la privacidad del saldo
final isBalancePrivateProvider = StateProvider<bool>((ref) => false);

/// Provider local para controlar si ya se sincronizaron las notificaciones en la sesión actual
final hasSyncedNotificationsProvider = StateProvider<bool>((ref) => false);

/// Provider local para controlar si ya se solicitaron los permisos de notificación en esta sesión
final hasRequestedPermissionsProvider = StateProvider<bool>((ref) => false);

/// Provider combinado para el cálculo automático y determinístico del Saldo Disponible
final saldoDisponibleProvider = Provider<AsyncValue<double>>((ref) {
  final ingresosAsync = ref.watch(totalIngresosMesActualProvider);
  final egresosAsync = ref.watch(totalEgresoMesActualProvider);

  return ingresosAsync.when(
    data: (ingresos) => egresosAsync.when(
      data: (egresos) => AsyncValue.data(ingresos - egresos),
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Provider que calcula la variación porcentual con respecto al mes anterior
final variacionSaldoMesAnteriorProvider = Provider<AsyncValue<double?>>((ref) {
  final ingresosActualAsync = ref.watch(totalIngresosMesActualProvider);
  final egresosActualAsync = ref.watch(totalEgresoMesActualProvider);
  final ingresosAnteriorAsync = ref.watch(totalIngresosMesAnteriorProvider);
  final egresosAnteriorAsync = ref.watch(totalEgresoMesAnteriorProvider);

  if (ingresosActualAsync.isLoading ||
      egresosActualAsync.isLoading ||
      ingresosAnteriorAsync.isLoading ||
      egresosAnteriorAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final ingresosActual = ingresosActualAsync.value ?? 0.0;
  final egresosActual = egresosActualAsync.value ?? 0.0;
  final saldoActual = ingresosActual - egresosActual;

  final ingresosAnterior = ingresosAnteriorAsync.value ?? 0.0;
  final egresosAnterior = egresosAnteriorAsync.value ?? 0.0;
  final saldoAnterior = ingresosAnterior - egresosAnterior;

  // Si en el mes actual no hay movimientos registrados (0 ingresos y 0 gastos),
  // o si no hubo saldo en el mes anterior, no aplica porcentaje de variación.
  if ((ingresosActual == 0.0 && egresosActual == 0.0) || saldoAnterior == 0.0) {
    return const AsyncValue.data(null);
  }

  final variacion =
      ((saldoActual - saldoAnterior) / saldoAnterior.abs()) * 100.0;
  return AsyncValue.data(variacion);
});
