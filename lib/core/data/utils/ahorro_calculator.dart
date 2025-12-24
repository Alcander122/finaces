// 📊 core/data/utils/ahorro_calculator.dart
// ============================================================================
// CLASE: AhorroCalculator + AhorroDesglose (VERSIÓN SEGURA Y ROBUSTA)
// ============================================================================

/// 🎯 Clase principal que realiza todos los cálculos de ahorro
class AhorroCalculator {
  /// 🔹 Calcula el desglose completo de ahorros
  static AhorroDesglose calcularDesglose({
    required double montoObjetivo,
    required DateTime fechaObjetivo,
    DateTime? fechaInicio,
  }) {
    fechaInicio ??= DateTime.now();

    // VALIDACIÓN: Fecha objetivo debe ser futura
    if (fechaObjetivo.isBefore(fechaInicio)) {
      return AhorroDesglose.fechaPasada(
        montoObjetivo: montoObjetivo,
        fechaInicio: fechaInicio,
        fechaObjetivo: fechaObjetivo,
      );
    }

    final diasRestantes = fechaObjetivo.difference(fechaInicio).inDays;

    if (diasRestantes <= 0) {
      return AhorroDesglose.fechaPasada(
        montoObjetivo: montoObjetivo,
        fechaInicio: fechaInicio,
        fechaObjetivo: fechaObjetivo,
      );
    }

    final ahorrosDiarios = montoObjetivo / diasRestantes;
    final ahorrosSemanal = ahorrosDiarios * 7;
    final ahorrosQuincenal = ahorrosDiarios * 15;
    final ahorrosMensual = ahorrosDiarios * 30;

    return AhorroDesglose.valido(
      montoObjetivo: montoObjetivo,
      fechaInicio: fechaInicio,
      fechaObjetivo: fechaObjetivo,
      diasRestantes: diasRestantes,
      ahorrosDiarios: ahorrosDiarios,
      ahorrosSemanal: ahorrosSemanal,
      ahorrosQuincenal: ahorrosQuincenal,
      ahorrosMensual: ahorrosMensual,
    );
  }

  static int calcularDiasRestantes(DateTime fechaObjetivo) {
    return fechaObjetivo.difference(DateTime.now()).inDays;
  }

  static double calcularSemanasRestantes(DateTime fechaObjetivo) {
    final dias = calcularDiasRestantes(fechaObjetivo);
    return dias / 7;
  }

  static double calcularMesesRestantes(DateTime fechaObjetivo) {
    final dias = calcularDiasRestantes(fechaObjetivo);
    return dias / 30;
  }
}

// ============================================================================
// CLASE: AhorroDesglose
// ============================================================================

class AhorroDesglose {
  final double montoObjetivo;
  final DateTime fechaInicio;
  final DateTime fechaObjetivo;
  final int diasRestantes;
  final double ahorrosDiarios;
  final double ahorrosSemanal;
  final double ahorrosQuincenal;
  final double ahorrosMensual;
  final bool esValido;

  /// Constructor principal (todos los parámetros required)
  const AhorroDesglose({
    required this.montoObjetivo,
    required this.fechaInicio,
    required this.fechaObjetivo,
    required this.diasRestantes,
    required this.ahorrosDiarios,
    required this.ahorrosSemanal,
    required this.ahorrosQuincenal,
    required this.ahorrosMensual,
    required this.esValido,
  });

  /// 🔥 Factory: Caso válido (cálculo exitoso)
  factory AhorroDesglose.valido({
    required double montoObjetivo,
    required DateTime fechaInicio,
    required DateTime fechaObjetivo,
    required int diasRestantes,
    required double ahorrosDiarios,
    required double ahorrosSemanal,
    required double ahorrosQuincenal,
    required double ahorrosMensual,
  }) {
    return AhorroDesglose(
      montoObjetivo: montoObjetivo,
      fechaInicio: fechaInicio,
      fechaObjetivo: fechaObjetivo,
      diasRestantes: diasRestantes,
      ahorrosDiarios: ahorrosDiarios,
      ahorrosSemanal: ahorrosSemanal,
      ahorrosQuincenal: ahorrosQuincenal,
      ahorrosMensual: ahorrosMensual,
      esValido: true,
    );
  }

  /// 🔥 Factory: Caso inválido - Fecha ya pasó o datos inconsistentes
  factory AhorroDesglose.fechaPasada({
    required double montoObjetivo,
    required DateTime fechaInicio,
    required DateTime fechaObjetivo,
  }) {
    return AhorroDesglose(
      montoObjetivo: montoObjetivo,
      fechaInicio: fechaInicio,
      fechaObjetivo: fechaObjetivo,
      diasRestantes: 0,
      ahorrosDiarios: 0.0,
      ahorrosSemanal: 0.0,
      ahorrosQuincenal: 0.0,
      ahorrosMensual: 0.0,
      esValido: false,
    );
  }

  /// 🔥 Factory: Caso inválido genérico (para errores inesperados o datos corruptos)
  factory AhorroDesglose.invalido({
    required double montoObjetivo,
    required DateTime fechaInicio,
    required DateTime fechaObjetivo,
  }) {
    return AhorroDesglose(
      montoObjetivo: montoObjetivo,
      fechaInicio: fechaInicio,
      fechaObjetivo: fechaObjetivo,
      diasRestantes: 0,
      ahorrosDiarios: 0.0,
      ahorrosSemanal: 0.0,
      ahorrosQuincenal: 0.0,
      ahorrosMensual: 0.0,
      esValido: false,
    );
  }

  /// Mensaje amigable sobre tiempo restante
  String get mensajeTiempoRestante {
    if (diasRestantes <= 0) {
      return 'La fecha ya pasó';
    } else if (diasRestantes == 1) {
      return '1 día restante';
    } else if (diasRestantes < 7) {
      return '$diasRestantes días restantes';
    } else if (diasRestantes < 30) {
      final semanas = (diasRestantes / 7).toStringAsFixed(1);
      return '$semanas semanas restantes';
    } else {
      final meses = (diasRestantes / 30).toStringAsFixed(1);
      return '$meses meses restantes';
    }
  }

  /// Período recomendado según tiempo disponible
  String get periodoRecomendado {
    if (diasRestantes <= 7) return 'diario';
    if (diasRestantes <= 30) return 'semanal';
    if (diasRestantes <= 90) return 'quincenal';
    return 'mensual';
  }
}
