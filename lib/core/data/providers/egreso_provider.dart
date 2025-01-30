import 'package:finances/core/data/models/egreso_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/services/egreso_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

final egresoServiceProvider = Provider<EgresoService>((ref) {
  return EgresoService();
});

final egresosProvider = StreamProvider.autoDispose<List<Egreso>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final service = ref.watch(egresoServiceProvider);
    return service.obtenerEgresos(user.uid);
  } else {
    return Stream.value([]);
  }
});

final totalGastosProvider = StreamProvider.autoDispose<double>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final service = ref.watch(egresoServiceProvider);
    return service.streamTotalGastos(user.uid);
  } else {
    return Stream.value(0.0);
  }
});
