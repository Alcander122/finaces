// utils/ui_helpers.dart
import 'package:finances/core/errors/handlers/auth_error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Clase de utilidades generales para UI: SnackBars, diálogos, formateo y textos centralizados.
class UIHelpers {
  // ===================== MENSAJES CENTRALIZADOS =====================

  /// Acceso estático a las cadenas de texto del módulo de portafolios e inversiones
  static const strings = PortafolioStrings();

  // ===================== SNACKBARS =====================

  /// Muestra un SnackBar de éxito (verde)
  static void showSuccessSnackBar({
    required BuildContext context,
    required String message,
  }) {
    _showSnackBar(context, message, backgroundColor: Colors.green);
  }

  /// Muestra un SnackBar de error (rojo)
  static void showErrorSnackBar({
    required BuildContext context,
    required String message,
  }) {
    _showSnackBar(context, message, backgroundColor: Colors.red);
  }

  /// Muestra un SnackBar de error de Firebase usando AuthErrorHandler
  static void showErrorSnackBarFromAuth({
    required BuildContext context,
    required FirebaseAuthException error,
  }) {
    final message = AuthErrorHandler.handle(error);
    _showSnackBar(context, message, backgroundColor: Colors.red);
  }

  /// Muestra un SnackBar informativo (azul)
  static void showInfoSnackBar({
    required BuildContext context,
    required String message,
  }) {
    _showSnackBar(context, message, backgroundColor: Colors.blue);
  }

  /// Método privado: evita duplicación y asegura seguridad
  static void _showSnackBar(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.black,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ===================== DIÁLOGOS =====================

  /// Muestra diálogo de carga
  static void showLoadingDialog(
    BuildContext context, {
    String message = 'Cargando...',
  }) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Cierra diálogo de carga
  static void hideLoadingDialog(BuildContext context) {
    if (!context.mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  // ===================== FORMATEO DE MONEDA Y NÚMEROS =====================

  /// Formatea un monto en COP con el símbolo $ y separador de miles colombiano (ej. $1.000.000)
  static String formatCurrency(double value, {bool showDecimals = false}) {
    final formatter = NumberFormat.decimalPattern('es_CO');
    return '\$${formatter.format(showDecimals ? value : value.round())}';
  }

  /// Retorna el símbolo de la divisa según la norma internacional
  static String formatCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'USD':
        return 'US\$';
      default:
        return '\$';
    }
  }

  /// Formatea un valor numérico con separador de miles colombiano (ej. 1.000.000 o 1.250,50)
  static String formatDecimal(num value, {int decimalDigits = 0}) {
    if (decimalDigits > 0) {
      final pattern = '#,##0.${'0' * decimalDigits}';
      return NumberFormat(pattern, 'es_CO').format(value);
    }
    return NumberFormat.decimalPattern('es_CO').format(value.round());
  }

  /// Formatea una cantidad con el símbolo de divisa correspondiente (ej. US$ 1.500 o € 2.000)
  static String formatCurrencyAmount(
    double value, {
    String currency = 'COP',
    int decimalDigits = 0,
  }) {
    final symbol = formatCurrencySymbol(currency);
    final formattedNum = formatDecimal(value, decimalDigits: decimalDigits);
    return '$symbol $formattedNum';
  }

  /// Formatea un monto en moneda extranjera con su código al final (ej. ≈ US$ 1.250,00 USD)
  static String formatForeignCurrency(
    double value,
    String currency, {
    int decimalDigits = 2,
  }) {
    final symbol = formatCurrencySymbol(currency);
    final formatted = formatDecimal(value, decimalDigits: decimalDigits);
    return '≈ $symbol $formatted ${currency.toUpperCase()}';
  }

  /// Formatea un porcentaje con signo opcional (ej. +12.5% o 8.0%)
  static String formatPercentage(
    double value, {
    int decimalDigits = 1,
    bool includeSign = false,
  }) {
    final sign = includeSign && value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(decimalDigits)}%';
  }

  /// Formatea tasas de cambio con hasta 4 decimales
  static String formatRate(double rate, {String toCurrency = 'COP'}) {
    final formatter = NumberFormat('#,##0.####', 'es_CO');
    final symbol = formatCurrencySymbol(toCurrency);
    return '$symbol${formatter.format(rate)}';
  }
}

/// Mensajes y textos centralizados para el módulo de Portafolio e Inversiones
class PortafolioStrings {
  const PortafolioStrings();

  // --- TÍTULOS Y ACCIONES DE PANTALLA ---
  static const String misPortafoliosTitle = 'Mis Portafolios';
  static const String nuevoPortafolioBtn = 'Nuevo Portafolio';
  static const String nuevaInversionBtn = 'Nueva Inversión';
  static const String simuladorTitle = 'Simulador de Inversiones';
  static String simuladorTitleWithAsset(String title) => 'Simulador: $title';
  static const String iniciarSesionRequerido =
      'Inicia sesión para ver tus portafolios de inversión';

  // --- TOOLTIPS Y SEMÁNTICA ---
  static const String simuladorTooltip = 'Simulador de Inversiones';
  static const String editarPortafolioTooltip = 'Editar Portafolio';
  static const String eliminarPortafolioTooltip = 'Eliminar Portafolio';
  static const String editarInversionTooltip = 'Editar Inversión';
  static const String eliminarInversionTooltip = 'Eliminar Inversión';
  static const String simularProyeccionTooltip = 'Simular Proyección';
  static const String compartirExportarTooltip = 'Compartir / Exportar';
  static const String compartirExportarBtn = 'Compartir o Exportar Proyección';
  static const String cancelarBtn = 'Cancelar';
  static const String eliminarBtn = 'Eliminar';
  static const String guardarBtn = 'Guardar';
  static const String crearPortafolioTitle = 'Crear Portafolio';
  static const String editarPortafolioTitle = 'Editar Portafolio';

  // --- MENSAJES DE ÉXITO Y NOTIFICACIONES ---
  static const String portafolioEliminadoExito = 'Portafolio eliminado con éxito';
  static const String inversionEliminadaExito = 'Inversión eliminada con éxito';
  static const String portafolioCreadoExito = 'Portafolio creado correctamente';
  static const String portafolioActualizadoExito =
      'Portafolio actualizado correctamente';
  static const String inversionGuardadaExito = 'Inversión guardada con éxito';
  static const String trmActualizadaExito =
      'Tasas de cambio actualizadas correctamente';
  static const String trmActualizadaError =
      'No se pudo actualizar la TRM. Usando última tasa disponible.';
  static String shareError(dynamic e) => 'Error al compartir la proyección: $e';
  static String shareSubject(String title) => 'Simulación de Inversión: $title';

  // --- DIÁLOGOS DE CONFIRMACIÓN ---
  static const String eliminarPortafolioDialogTitle = 'Eliminar Portafolio';
  static String eliminarPortafolioDialogMsg(String nombre) =>
      '¿Deseas eliminar "$nombre" y todas sus inversiones asociadas de manera permanente?';
  static const String eliminarInversionDialogTitle = 'Eliminar Inversión';
  static String eliminarInversionDialogMsg(String descripcion) =>
      '¿Estás seguro de que deseas eliminar "$descripcion" de este portafolio?';

  // --- ESTADOS VACÍOS ---
  static const String emptyPortafolioTitle = 'Comienza tu Portafolio';
  static const String emptyPortafolioDesc =
      'Organiza y supervisa tus inversiones, acciones, fondos o criptomonedas de forma inteligente en un solo lugar.';
  static const String emptyPortafolioBtn = 'Crear mi primer portafolio';

  static const String emptyInversionTitle = 'Sin Inversiones Aún';
  static String emptyInversionDesc(String nombre) =>
      'Agrega activos como acciones, criptos o fondos a "$nombre" para comenzar a visualizar su evolución.';
  static const String emptyInversionBtn = 'Agregar Inversión';

  // --- KPIS Y ENCABEZADOS ---
  static const String kpiPatrimonioTotal = 'Patrimonio Total';
  static const String kpiPortafolios = 'Portafolios';
  static const String kpiActivosCartera = 'Activos en Cartera';
  static String tusPortafoliosCount(int count) => 'Tus Portafolios ($count)';
  static String portafoliosRegistradosCount(int count) =>
      'Portafolios Registrados ($count)';
  static String inversionesCount(int count) => 'Inversiones ($count)';
  static String inversionesPortafolioCount(int count) =>
      'Inversiones del Portafolio ($count)';
  static const String valorTotalLabel = 'Valor Total';
  static const String valorConsolidadoLabel = 'Valor Consolidado';
  static String inversionesBadge(int count) =>
      '$count ${count == 1 ? "inversión" : "inversiones"}';

  // --- SIMULADOR DE INVERSIONES ---
  static const String valorFuturoProyectado = 'Valor Futuro Proyectado';
  static String plazoMesesYAnos(int meses) =>
      'En $meses meses (${(meses / 12).toStringAsFixed(1)} años)';
  static String plazoDisplay(int meses) =>
      '$meses meses (${(meses / 12).toStringAsFixed(1)} años)';
  static const String capitalAportadoLabel = 'Capital Aportado';
  static const String gananciaInteresesLabel = 'Ganancia Intereses';
  static String efectoCambiarioBadge(double diff) =>
      'Efecto Cambiario por TRM (${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(1)}%):';
  static String trmBadge(double diff) =>
      'TRM ${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(1)}%';
  static String sensibilidadCambiariaTitle(String currency) =>
      'Sensibilidad Cambiaria ($currency/COP)';
  static String trmBaseOficialLabel(String trm) => 'TRM base oficial: $trm';
  static const String trmSimuladaProyectadaLabel = 'TRM Simulada Proyectada:';
  static const String escenariosMercadoLabel =
      'Escenarios de mercado preestablecidos:';
  static const String configuracionSimulacionTitle =
      'Configuración de la Simulación';
  static String capitalInicialLabel(String symbol) =>
      'Capital Inicial ($symbol)';
  static const String aportesRecurrentesTitle =
      'Aportes recurrentes periódicos';
  static const String aportesRecurrentesSubtitle =
      'Simula invertir una cantidad adicional cada mes';
  static String aporteMensualLabel(String symbol) =>
      'Aporte Mensual Adicional ($symbol)';
  static const String tasaEstimadaLabel = 'Tasa Estimada (% E.A.)';
  static String tasaEaBadge(double rate) => '${rate.toStringAsFixed(1)}% E.A.';
  static const String tasasReferenciaLabel = 'Tasas de referencia sugeridas:';
  static const String plazoInversionLabel = 'Plazo de la Inversión';
  static String trmApreciacionMsg(String currency, String trm, String impacto) =>
      '💡 Si el $currency se valoriza a $trm, tu rentabilidad en pesos se incrementará en $impacto por efecto cambiario.';
  static String trmAmortiguacionMsg(String trm, String impacto) =>
      '⚠️ Si el peso colombiano se fortalece a $trm, tu rentabilidad en COP se verá amortiguada en $impacto.';

  // --- TRM INDICATOR ---
  static const String trmHeaderTitle = 'Tasas de Cambio de Referencia';
  static const String trmCargando = 'Cargando tasas de cambio...';
  static const String trmError = 'No se pudieron cargar las tasas de cambio';
  static const String trmActualizado = 'Actualizado:';
  static const String trmEnCache = 'Caché';
}
