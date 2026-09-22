import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/core/data/providers/Ingreso_provider.dart';
import 'package:finances/core/data/providers/egreso_provider.dart';
import 'package:finances/core/data/utils/ui_helpers.dart';
import 'package:finances/presentations/screens/home/providers/home_providers.dart';
import 'package:finances/presentations/screens/home/widgets/home_glassmorphic_card.dart';
import 'package:finances/presentations/screens/movimientos/movimientos_screen.dart';
import 'package:finances/presentations/theme/theme.dart';

class HomeBalanceCard extends ConsumerWidget {
  const HomeBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saldoAsync = ref.watch(saldoDisponibleProvider);
    final variacionAsync = ref.watch(variacionSaldoMesAnteriorProvider);
    final totalIngresosAsync = ref.watch(totalIngresosMesActualProvider);
    final totalGastosAsync = ref.watch(totalEgresoMesActualProvider);
    final isPrivate = ref.watch(isBalancePrivateProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: HomeGlassmorphicCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: etiqueta y botón de privacidad
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: context.colors.onSurface.withValues(alpha: 0.5),
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PLATA DISPONIBLE',
                      style: TextStyle(
                        color: context.colors.onSurface.withValues(alpha: 0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(isBalancePrivateProvider.notifier).state =
                        !isPrivate;
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      isPrivate
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: context.colors.onSurface.withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Saldo disponible principal
            saldoAsync.when(
              data: (saldo) => Text(
                isPrivate ? '••••••••' : UIHelpers.formatCurrency(saldo),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: (saldo < 0 && !isPrivate)
                      ? const Color(0xFFEF5350)
                      : context.colors.onSurface,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              loading: () => const SizedBox(
                height: 40,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF26A69A),
                  ),
                ),
              ),
              error: (e, _) => Text(
                r'$-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.onSurface,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Badge de variación respecto al mes anterior
            _buildVariationBadge(context, variacionAsync, saldoAsync),
            const SizedBox(height: 20),

            // Divisor
            Container(
              height: 1,
              color: context.colors.onSurface.withValues(alpha: 0.08),
            ),
            const SizedBox(height: 16),

            // Mini-estadísticas de Ingresos y Gastos (táctiles hacia MovimientosScreen)
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    context: context,
                    label: 'Ingresos',
                    amountAsync: totalIngresosAsync,
                    isIncome: true,
                    isPrivate: isPrivate,
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: context.colors.onSurface.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: _buildMiniStat(
                    context: context,
                    label: 'Gastos',
                    amountAsync: totalGastosAsync,
                    isIncome: false,
                    isPrivate: isPrivate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariationBadge(
    BuildContext context,
    AsyncValue<double?> variacionAsync,
    AsyncValue<double> saldoAsync,
  ) {
    return saldoAsync.when(
      data: (saldo) {
        return variacionAsync.when(
          data: (variacion) {
            if (variacion != null) {
              final isPositive = variacion >= 0;
              final color = isPositive
                  ? const Color(0xFF26A69A)
                  : const Color(0xFFEF5350);
              final icon = isPositive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded;
              final sign = isPositive ? '+' : '';
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$sign${variacion.toStringAsFixed(1)}% respecto al mes anterior',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }

            final isZero = saldo == 0;
            final badgeColor = isZero
                ? context.colors.onSurface.withValues(alpha: 0.45)
                : const Color(0xFF26A69A);
            final badgeText = isZero
                ? '● Sin movimientos este mes'
                : '● Balance del mes activo';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMiniStat({
    required BuildContext context,
    required String label,
    required AsyncValue<double> amountAsync,
    required bool isIncome,
    required bool isPrivate,
  }) {
    final themeColor =
        isIncome ? const Color(0xFF26A69A) : const Color(0xFFEF5350);

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).clearSnackBars();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovimientosScreen(initialTab: isIncome ? 1 : 0),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: themeColor,
                size: 15,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  amountAsync.when(
                    data: (amount) => Text(
                      isPrivate ? '••••' : UIHelpers.formatCurrency(amount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    loading: () => SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colors.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                    error: (_, __) => Text(
                      r'$-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
