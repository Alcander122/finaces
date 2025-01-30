import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/services/ingresos_service.dart';
import 'package:finances/core/data/providers/auth_provider.dart';

// Proveedor para escuchar ingresos en tiempo real
final totalIngresosProvider = StreamProvider.autoDispose<double>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value(0.0);
  return IngresosService().streamTotalIngresos(user.uid);
});
