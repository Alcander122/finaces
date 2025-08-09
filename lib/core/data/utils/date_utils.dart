// lib/core/utils/date_utils.dart
import 'package:intl/intl.dart';

/// Clase de utilidades para manejar fechas de manera consistente en toda la aplicación
///
/// Propósito:
/// - Proporcionar métodos estáticos para calcular rangos de fecha
/// - Asegurar consistencia en el cálculo de fechas entre diferentes componentes
/// - Eliminar la duplicación de lógica de cálculo de fechas
///
/// Importancia:
/// Sin esta clase, los diferentes componentes calcularían fechas de manera inconsistente,
/// causando valores incorrectos al aplicar filtros (especialmente en el último día del mes)
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

  /// Obtiene el primer día del trimestre actual
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
