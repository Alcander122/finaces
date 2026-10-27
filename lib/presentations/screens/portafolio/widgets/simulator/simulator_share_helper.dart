import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';

/// Helper para formatear y compartir el resumen de la proyección de inversión
class SimulatorShareHelper {
  static Future<void> share({
    required BuildContext context,
    required String? title,
    required String selectedCurrency,
    required bool hasForeignCurrency,
    required double capitalInicial,
    required double aporteMensual,
    required bool esAporteRecurrente,
    required int plazoMeses,
    required double tasaEA,
    required double balanceMoneda,
    required double capitalAportadoMoneda,
    required double gananciaInteresesMoneda,
    required double valorFinalCOP,
    required double capitalAportadoCOP,
    required double gananciaInteresesCOP,
    required double impactoCambiarioCOP,
    required double baseTrm,
    required double simulatedTrm,
    required double trmDiffPct,
    required double rendimientoTotalPorcentaje,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    final resolvedTitle = title ?? 'Proyección Financiera';
    final symbol = UIHelpers.formatCurrencySymbol(selectedCurrency);

    final buffer = StringBuffer();
    buffer.writeln('📊 *Simulación de Inversión - BillNance*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💼 *Inversión:* $resolvedTitle');
    buffer.writeln('💱 *Moneda:* $selectedCurrency');
    buffer.writeln(
        '💰 *Capital Inicial:* $symbol ${UIHelpers.formatDecimal(capitalInicial.round())}');
    if (esAporteRecurrente && aporteMensual > 0) {
      buffer.writeln(
          '🔄 *Aporte Periódico Mensual:* $symbol ${UIHelpers.formatDecimal(aporteMensual.round())}');
    }
    buffer.writeln('⏱️ *Plazo:* ${PortafolioStrings.plazoDisplay(plazoMeses)}');
    buffer.writeln('📈 *Tasa Estimada:* ${PortafolioStrings.tasaEaBadge(tasaEA)}');

    if (hasForeignCurrency) {
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('🌐 *ESCENARIO CAMBIARIO (TRM):*');
      buffer.writeln(
          '• TRM Base Oficial: ${UIHelpers.formatCurrency(baseTrm)}');
      buffer.writeln(
          '• TRM Simulada: ${UIHelpers.formatCurrency(simulatedTrm)} (${UIHelpers.formatPercentage(trmDiffPct, includeSign: true)})');
      buffer.writeln(
          '• Efecto Cambiario: ${impactoCambiarioCOP >= 0 ? '+' : ''}${UIHelpers.formatCurrency(impactoCambiarioCOP)}');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🎯 *RESULTADOS PROYECTADOS:*');
    if (hasForeignCurrency) {
      buffer.writeln(
          '• Total Capital Aportado: $symbol ${UIHelpers.formatDecimal(capitalAportadoMoneda.round())} (${UIHelpers.formatCurrency(capitalAportadoCOP)})');
      buffer.writeln(
          '• Ganancia por Intereses: $symbol ${UIHelpers.formatDecimal(gananciaInteresesMoneda.round())} (${UIHelpers.formatCurrency(gananciaInteresesCOP)})');
      buffer.writeln(
          '• Rendimiento Total: ${UIHelpers.formatPercentage(rendimientoTotalPorcentaje, includeSign: true)}');
      buffer.writeln(
          '🚀 *VALOR FINAL PROYECTADO: ${UIHelpers.formatCurrency(valorFinalCOP)}* ($symbol ${UIHelpers.formatDecimal(balanceMoneda, decimalDigits: 2)})');
    } else {
      buffer.writeln(
          '• Total Capital Aportado: ${UIHelpers.formatCurrency(capitalAportadoCOP)}');
      buffer.writeln(
          '• Ganancia por Intereses: ${UIHelpers.formatCurrency(gananciaInteresesCOP)}');
      buffer.writeln(
          '• Rendimiento Total: ${UIHelpers.formatPercentage(rendimientoTotalPorcentaje, includeSign: true)}');
      buffer.writeln(
          '🚀 *VALOR FINAL PROYECTADO: ${UIHelpers.formatCurrency(valorFinalCOP)}*');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📱 _Generado con BillNance App_');

    try {
      await Share.share(
        buffer.toString(),
        subject: PortafolioStrings.shareSubject(resolvedTitle),
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      if (context.mounted) {
        UIHelpers.showErrorSnackBar(
          context: context,
          message: PortafolioStrings.shareError(e),
        );
      }
    }
  }
}
