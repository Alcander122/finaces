import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/screens/home/widgets/home_glassmorphic_card.dart';
import 'package:finances/presentations/theme/theme.dart';

class HomeSmartTip extends ConsumerWidget {
  const HomeSmartTip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalGastosAsync = ref.watch(totalEgresoMesActualProvider);
    final totalIngresosAsync = ref.watch(totalIngresosMesActualProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: totalGastosAsync.when(
        data: (gastos) {
          final ingresos = totalIngresosAsync.value ?? 0.0;
          final String consejoText;
          final Color bulbColor;

          if (gastos == 0 && ingresos == 0) {
            consejoText =
                '¡Bienvenido a tu panel de control! Registra tus primeros movimientos con el botón de Movimientos para activar tus métricas y consejos personalizados.';
            bulbColor = const Color(0xFFFFB74D);
          } else if (gastos == 0 && ingresos > 0) {
            consejoText =
                '¡Excelente inicio! Has registrado ${UIHelpers.formatCurrency(ingresos)} en ingresos y aún no tienes gastos este mes. ¡Sigue así!';
            bulbColor = const Color(0xFF26A69A);
          } else if (ingresos == 0 && gastos > 0) {
            consejoText =
                'Has registrado ${UIHelpers.formatCurrency(gastos)} en gastos, pero aún no registras ingresos este mes. ¡Agrega tus ingresos para ver tu balance real!';
            bulbColor = const Color(0xFFEF5350);
          } else {
            final ratio = (gastos / ingresos) * 100;
            if (ratio > 100) {
              consejoText =
                  'Alerta de déficit: Tus gastos superan tus ingresos en un ${ratio.toStringAsFixed(0)}% este mes. Te sugerimos moderar egresos no esenciales.';
              bulbColor = const Color(0xFFEF5350);
            } else if (ratio > 80) {
              consejoText =
                  'Atención: Has consumido el ${ratio.toStringAsFixed(0)}% de tus ingresos este mes. Te recomendamos pausar gastos no esenciales.';
              bulbColor = const Color(0xFFFF7043);
            } else if (ratio > 50) {
              consejoText =
                  'Moderado: Has consumido el ${ratio.toStringAsFixed(0)}% de tus ingresos este mes. Procura vigilar tus egresos diarios.';
              bulbColor = const Color(0xFFFFB74D);
            } else {
              consejoText =
                  '¡Excelente ritmo! Has consumido solo el ${ratio.toStringAsFixed(0)}% de tus ingresos. Mantienes un control financiero impecable.';
              bulbColor = const Color(0xFF26A69A);
            }
          }

          return HomeGlassmorphicCard(
            padding: const EdgeInsets.all(16.0),
            borderRadius: 16.0,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bulbColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: bulbColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    consejoText,
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.75),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
