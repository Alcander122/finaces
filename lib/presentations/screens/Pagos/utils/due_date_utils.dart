import 'package:timezone/timezone.dart' as tz;

class DueDateUtils {
  /// Agrega meses a una fecha asegurando el comportamiento "Snap to End of Month".
  /// Ej: 31 Enero + 1 mes = 28 Febrero (o 29 en bisiestos).
  static tz.TZDateTime addMonthsWithSnapToEnd(tz.TZDateTime date, int months) {
    int newYear = date.year;
    int newMonth = date.month + months;

    // Calcular el salto real de años si los meses superan 12
    while (newMonth > 12) {
      newYear++;
      newMonth -= 12;
    }
    // Calcular el salto hacia atrás si sumamos meses negativos
    while (newMonth < 1) {
      newYear--;
      newMonth += 12;
    }

    // Obtener cuántos días tiene el nuevo mes destino
    final daysInNewMonth = _daysInMonth(newYear, newMonth);

    // Snap to end: Si el día original es mayor a los días que tiene el mes destino, usar el límite del mes destino.
    int newDay = date.day;
    if (newDay > daysInNewMonth) {
      newDay = daysInNewMonth;
    }

    return tz.TZDateTime(date.location, newYear, newMonth, newDay, date.hour, date.minute, date.second);
  }

  /// Devuelve el número de días en un mes específico, contemplando años bisiestos.
  static int _daysInMonth(int year, int month) {
    if (month == 2) {
      bool isLeapYear = (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
      return isLeapYear ? 29 : 28;
    }
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month - 1];
  }
}
