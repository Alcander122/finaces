// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/portafolio_model.dart';
import '../services/portafolio_service.dart';

final portafolioServiceProvider = Provider((ref) => PortafolioService());

final portafoliosProvider =
    StreamProvider.family<List<Portafolio>, String>((ref, userId) {
  return ref
      .watch(portafolioServiceProvider)
      .obtenerPortafoliosEnTiempoReal(userId);
});
