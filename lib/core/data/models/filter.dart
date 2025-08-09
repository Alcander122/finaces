import 'package:flutter/material.dart';

enum FilterType { monthly, quarterly, annual, custom }

class Filter {
  final FilterType type;

  final DateTime? startDate;
  final DateTime? endDate;

  const Filter({
    required this.type,
    this.startDate,
    this.endDate,
  });

  Filter validate() {
    if (type == FilterType.custom && (startDate == null || endDate == null)) {
      throw ArgumentError('Filtro personalizado requiere startDate y endDate');
    }
    return this;
  }

  DateTimeRange get dateRange {
    final now = DateTime.now();

    switch (type) {
      case FilterType.monthly:
        // Para el filtro mensual, el rango es del primer día al último día del mes actual
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1,
              0), // El 0 del siguiente mes es el último día del mes actual
        );

      case FilterType.quarterly:
        /*
         * CORRECCIÓN PARA FILTRO TRIMESTRAL:
         * 
         * El objetivo es mostrar siempre los últimos 3 meses COMPLETADOS,
         * independientemente de si el mes actual ha terminado o no.
         * 
         * Ejemplos:
         * - Si hoy es 15 de abril (abril no completado), debe mostrar enero, febrero y marzo
         * - Si hoy es 5 de mayo (abril completado), debe mostrar febrero, marzo y abril
         * - Si hoy es 10 de enero (diciembre completado), debe mostrar octubre, noviembre y diciembre del año anterior
         * 
         * Lógica implementada:
         * 1. Obtenemos el último día del mes anterior (mes completado más reciente)
         *    Usamos la técnica de DateTime(now.year, now.month, 0) que nos da el último día del mes anterior [[6]]
         * 2. Calculamos el mes de inicio restando 2 meses al mes del endDate (para obtener 3 meses completos)
         * 3. Ajustamos el año si el mes de inicio es menor que 1 (caso de enero, febrero, marzo)
         * 4. Creamos el rango de fecha desde el primer día del mes de inicio hasta el último día del mes anterior
         */
        final endDate =
            DateTime(now.year, now.month, 0); // Último día del mes anterior

        // Calculamos el mes de inicio (3 meses atrás desde el mes completado)
        int startMonth = endDate.month - 2;
        int startYear = endDate.year;

        // Ajustamos el año si el mes de inicio es menor que 1
        if (startMonth < 1) {
          startMonth += 12;
          startYear -= 1;
        }

        final startDate = DateTime(startYear, startMonth, 1);
        return DateTimeRange(
          start: startDate,
          end: endDate,
        );

      case FilterType.annual:
        // ¡ESTE ES EL CAMBIO CLAVE PARA TU FILTRO ANUAL!
        // Para el filtro anual, el rango es del 1 de enero al 31 de diciembre del año actual
        // Esto asegura que cuando el usuario seleccione "Anual", vea todo el año
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );

      case FilterType.custom:
        // Si es un filtro personalizado pero sin fechas definidas (caso raro),
        // usamos un mes por defecto para evitar errores
        if (startDate == null || endDate == null) {
          final defaultStart = now.subtract(const Duration(days: 30));
          return DateTimeRange(
            start: DateTime(defaultStart.year, defaultStart.month, 1),
            end: DateTime(now.year, now.month + 1, 0),
          );
        }
        return DateTimeRange(start: startDate!, end: endDate!);
    }
  }

  /// Método helper para crear fácilmente un filtro anual
  ///
  /// Uso: Filter.annual()
  ///
  /// Este método es especialmente útil cuando el usuario selecciona "Año actual"
  /// en la interfaz de usuario. Crea un filtro de tipo annual con las fechas
  /// correctas del año actual (1 de enero al 31 de diciembre).
  static Filter annual() {
    final now = DateTime.now();
    return Filter(
      type: FilterType.annual,
      startDate: DateTime(now.year, 1, 1),
      endDate: DateTime(now.year, 12, 31),
    ).validate();
  }

  /// Método helper para crear fácilmente un filtro mensual
  ///
  /// Uso: Filter.monthly()
  ///
  /// Crea un filtro de tipo monthly con las fechas del mes actual.
  /// Es el filtro predeterminado cuando inicia la aplicación.
  static Filter monthly() {
    final now = DateTime.now();
    return Filter(
      type: FilterType.monthly,
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
    ).validate();
  }

  /// Método helper para crear fácilmente un filtro personalizado
  ///
  /// Uso: Filter.custom(fechaInicio, fechaFin)
  ///
  /// Parámetros:
  /// - start: Fecha de inicio del rango
  /// - end: Fecha de fin del rango
  static Filter custom(DateTime start, DateTime end) {
    return Filter(
      type: FilterType.custom,
      startDate: start,
      endDate: end,
    ).validate();
  }

  /// Crea una copia del filtro con cambios parciales
  ///
  /// IMPORTANTE: Este método mantiene la inmutabilidad del estado,
  /// que es esencial para el correcto funcionamiento con Riverpod.
  ///
  /// Uso típico:
  /// currentFilter.copyWith(type: FilterType.annual)
  ///
  /// El método incluye validación automática para asegurar que el nuevo
  /// filtro sea válido antes de devolverlo.
  Filter copyWith({
    FilterType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Filter(
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    ).validate();
  }
}
