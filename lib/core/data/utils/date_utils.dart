// lib/core/utils/date_utils.dart
import 'package:intl/intl.dart';

/// Clase de utilidades para manejar fechas de manera consistente en toda la aplicación
class DateUtils {
  /// Obtiene el primer día del mes actual con hora mínima (00:00:00)
  ///
  /// Ejemplo: Si hoy es 15/08/2023, devuelve 01/08/2023 00:00:00
  ///
  /// Uso:
  /// - Para definir el inicio de un rango de fecha mensual
  /// - En los filtros de mes actual
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Obtiene el último día del mes actual con hora máxima (23:59:59.999)
  ///
  /// Ejemplo: Si hoy es 15/08/2023, devuelve 31/08/2023 23:59:59.999
  ///
  /// IMPORTANTE:
  /// Se usa 999 milisegundos para incluir TODOS los registros del último día
  /// Sin esto, algunos registros del último día podrían quedar excluidos
  static DateTime getEndOfMonth(DateTime date) {
    // El primer día del siguiente mes menos un día nos da el último día del mes actual
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  /// Obtiene el primer día del trimestre actual (trimestre de calendario)
  ///
  /// Un trimestre es un período de 3 meses:
  /// - Trimestre 1: Enero-Marzo
  /// - Trimestre 2: Abril-Junio
  /// - Trimestre 3: Julio-Septiembre
  /// - Trimestre 4: Octubre-Diciembre
  ///
  /// Cálculo:
  /// 1. Determina en qué trimestre está la fecha (1-4)
  /// 2. Calcula el mes de inicio del trimestre
  static DateTime getStartOfQuarter(DateTime date) {
    // Calcula el trimestre actual (1-4)
    int quarter = ((date.month - 1) ~/ 3) + 1;
    // Calcula el mes de inicio del trimestre
    int startMonth = (quarter - 1) * 3 + 1;
    return DateTime(date.year, startMonth, 1);
  }

  /// Obtiene el último día del trimestre actual con hora máxima
  static DateTime getEndOfQuarter(DateTime date) {
    int quarter = ((date.month - 1) ~/ 3) + 1;
    int endMonth = quarter * 3;
    return DateTime(date.year, endMonth + 1, 0, 23, 59, 59, 999);
  }

  /// 🔹 Obtiene el primer día del TRIMESTRE MÓVIL (últimos 3 meses completos antes del mes actual)
  ///
  /// Ejemplo:
  /// - Hoy: 15/08/2025 → 01/05/2025
  /// - Hoy: 10/01/2025 → 01/10/2024
  ///
  /// Uso:
  /// - Para definir un trimestre basado en últimos 3 meses completos
  /// - Más intuitivo para el usuario que un trimestre de calendario
  static DateTime getStartOfRollingQuarter(DateTime date) {
    return DateTime(date.year, date.month - 3, 1);
  }

  /// 🔹 Obtiene el último día del TRIMESTRE MÓVIL con hora máxima (23:59:59.999)
  ///
  /// Ejemplo:
  /// - Hoy: 15/08/2025 → 31/07/2025 23:59:59.999
  /// - Hoy: 10/01/2025 → 31/12/2024 23:59:59.999
  static DateTime getEndOfRollingQuarter(DateTime date) {
    return DateTime(date.year, date.month, 0, 23, 59, 59, 999);
  }

  /// Obtiene el primer día del año actual
  static DateTime getStartOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// Obtiene el último día del año actual con hora máxima
  static DateTime getEndOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59, 999);
  }

  /// Formatea una fecha para mostrar en UI
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
